defmodule EXGBoost.Training.Callback do
  @moduledoc """
  Callbacks are a mechanism to hook into the training process and perform custom actions.

  Callbacks are structs with the following fields:
  * `event` - the event that triggers the callback
  * `fun` - the function to call when the callback is triggered
  * `name` - the name of the callback
  * `init_state` - the initial state of the callback

  The following events are supported:
  * `:before_training` - called before the training starts
  * `:after_training` - called after the training ends
  * `:before_iteration` - called before each iteration
  * `:after_iteration` - called after each iteration

  The callback function is called with the following arguments:
  * `state` - the current training state

  The callback function should return one of the following:
  * `{:cont, state}` - continue training with the given state
  * `{:halt, state}` - stop training with the given state

  The following callbacks are provided in the `EXGBoost.Training.Callback` module:
  * `lr_scheduler` - sets the learning rate for each iteration
  * `early_stop` - performs early stopping
  * `eval_metrics` - evaluates metrics on the training and evaluation sets
  * `eval_monitor` - prints evaluation metrics

  Callbacks can be added to the training process by passing them to `EXGBoost.Training.train/2`.

  ## Example

  ```elixir
  # Callback to perform setup before training
  setup_fn = fn state ->
    updated_state = put_in(state, [:meta_vars,:early_stop], %{best: 1, since_last_improvement: 0, mode: :max, patience: 5})
    {:cont, updated_state}
  end

  setup_callback = Callback.new(:before_training, setup_fn)
  ```

  """
  alias EXGBoost.Training.State
  @enforce_keys [:event, :fun]
  defstruct [:event, :fun, :name, :init_state]

  @type event :: :before_training | :after_training | :before_iteration | :after_iteration
  @type fun :: (State.t() -> State.t())

  @valid_events [:before_training, :after_training, :before_iteration, :after_iteration]

  @doc """
  Factory for a new callback with an initial state.
  """
  @spec new(event :: event(), fun :: fun(), name :: atom(), init_state :: any()) :: Callback.t()
  def new(event, fun, name, init_state \\ %{})
      when event in @valid_events and is_function(fun, 1) and is_atom(name) and not is_nil(name) do
    %__MODULE__{event: event, fun: fun, name: name, init_state: init_state}
    |> validate!()
  end

  def validate!(%__MODULE__{} = callback) do
    unless is_atom(callback.name) and not is_nil(callback.name) do
      raise "A callback must have a non-`nil` atom for a name. Found: #{callback.name}."
    end

    unless callback.event in @valid_events do
      raise "Callback #{callback.name} must have an event in #{@valid_events}. Found: #{callback.event}."
    end

    unless is_function(callback.fun, 1) do
      raise "Callback #{callback.name} must have a 1-arity function. Found: #{callback.event}."
    end

    callback
  end

  @doc """
  A callback that sets the learning rate for each iteration.

  Requires that `learning_rates` either be a list of learning rates or a function that takes the
  iteration number and returns a learning rate.  `learning_rates` must exist in the `state` that
  is passed to the callback.
  """
  def lr_scheduler(
        %State{
          booster: bst,
          meta_vars: %{lr_scheduler: %{learning_rates: learning_rates}},
          iteration: i,
          status: :cont
        } = state
      ) do
    lr = if is_list(learning_rates), do: Enum.at(learning_rates, i), else: learning_rates.(i)
    boostr = EXGBoost.Booster.set_params(bst, learning_rate: lr)
    %{state | booster: boostr}
  end

  # TODO: Ideally this would be generalized like it is in Axon to allow generic monitoring of metrics,
  # but for now we'll just do early stopping

  @doc """
  A callback function that performs early stopping.

  Requires that the following exist in the `state` that is passed to the callback:

  * `target` is the metric to monitor for early stopping.  It must exist in the `metrics` that the
  state contains.
  * `mode` is either `:min` or `:max` and indicates whether the metric should be
     minimized or maximized.
  * `patience` is the number of iterations to wait for the metric to improve before stopping.
  * `since_last_improvement` is the number of iterations since the metric last improved.
  * `best` is the best value of the metric seen so far.
  """
  def early_stop(
        %State{
          booster: bst,
          meta_vars: %{early_stop: early_stop} = meta_vars,
          metrics: metrics,
          status: :cont
        } = state
      ) do
    %{
      best: best_score,
      patience: patience,
      target_metric: target_metric,
      target_eval: target_eval,
      mode: mode,
      since_last_improvement: since_last_improvement
    } = early_stop

    unless Map.has_key?(metrics, target_eval) do
      raise ArgumentError,
            "target eval_set #{inspect(target_eval)} not found in metrics #{inspect(metrics)}"
    end

    unless Map.has_key?(metrics[target_eval], target_metric) do
      raise ArgumentError,
            "target metric #{inspect(target_metric)} not found in metrics #{inspect(metrics)}"
    end

    score = metrics[target_eval][target_metric]

    improved? =
      cond do
        best_score == nil -> true
        mode == :min -> score < best_score
        mode == :max -> score > best_score
      end

    cond do
      improved? ->
        early_stop = %{early_stop | best: score, since_last_improvement: 0}

        bst =
          bst
          |> struct(best_iteration: state.iteration, best_score: score)
          |> EXGBoost.Booster.set_attr(best_iteration: state.iteration, best_score: score)

        %{state | booster: bst, meta_vars: %{meta_vars | early_stop: early_stop}}

      since_last_improvement < patience ->
        early_stop = Map.update!(early_stop, :since_last_improvement, &(&1 + 1))
        %{state | meta_vars: %{meta_vars | early_stop: early_stop}}

      true ->
        early_stop = Map.update!(early_stop, :since_last_improvement, &(&1 + 1))
        # TODO: Should this actually update the best iteration and score?
        # This iteration is not the best, but it is the last one, so do we want
        # another way to track last iteration?
        bst = struct(bst, best_iteration: state.iteration, best_score: score)
        %{state | booster: bst, meta_vars: %{meta_vars | early_stop: early_stop}, status: :halt}
    end
  end

  @doc """
  A callback function that evaluates metrics on the training and evaluation sets.

  Requires that the following exist in the `state.meta_vars` that is passed to the callback:
   * eval_metrics:
      * evals: a list of evaluation sets to evaluate metrics on
      * filter: a function that takes a metric name and value and returns
      true if the metric should be included in the results
  """
  def eval_metrics(
        %State{
          booster: bst,
          iteration: iter,
          meta_vars: %{eval_metrics: %{evals: evals, filter: filter}},
          status: :cont
        } = state
      ) do
    metrics =
      EXGBoost.Booster.eval_set(bst, evals, iter)
      |> Enum.reduce(%{}, fn {evname, mname, value}, acc ->
        Map.update(acc, evname, %{mname => value}, fn existing ->
          Map.put(existing, mname, value)
        end)
      end)
      |> Map.filter(filter)

    %{state | metrics: metrics}
  end

  @doc """
  A callback function that prints evaluation metrics according to a period.

  Requires that the following exist in the `state.meta_vars` that is passed to the callback:
   * monitor_metrics:
      * period: print metrics every `period` iterations
      * filter: a function that takes a metric name and value and returns
      true if the metric should be included in the results
  """
  def monitor_metrics(
        %State{
          iteration: iteration,
          metrics: metrics,
          meta_vars: %{
            monitor_metrics: %{period: period, filter: filter}
          },
          status: :cont
        } = state
      ) do
    if period != 0 and rem(iteration, period) == 0 do
      IO.puts("Iteration #{iteration}: #{inspect(Map.filter(metrics, filter))}")
    end

    state
  end
end
