defmodule Exgboost.Training.Callback do
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

  The following callbacks are provided in the `Exgboost.Training.Callback` module:
  * `lr_scheduler` - sets the learning rate for each iteration
  * `early_stop` - performs early stopping
  * `eval_metrics` - evaluates metrics on the training and evaluation sets
  * `eval_monitor` - prints evaluation metrics

  Callbacks can be added to the training process by passing them to `Exgboost.Training.train/2`.

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
  alias Exgboost.Training.State
  @enforce_keys [:event, :fun]
  defstruct [:event, :fun, :name, :init_state]

  @doc """
  Factory for a new callback without an initial state. See `Exgboost.Callback.new/4` for more details.
  """
  @spec new(
          event :: :before_training | :after_training | :before_iteration | :after_iteration,
          fun :: (State.t() -> {:cont, State.t()} | {:halt, State.t()})
        ) :: Callback.t()
  def new(event, fun) do
    new(event, fun, nil, %{})
  end

  @doc """
  Factory for a new callback with an initial state.
  """
  @spec new(
          event :: :before_training | :after_training | :before_iteration | :after_iteration,
          fun :: (State.t() -> {:cont, State.t()} | {:halt, State.t()}),
          name :: atom(),
          init_state :: map()
        ) :: Callback.t()
  def new(event, fun, name, %{} = init_state)
      when event in [:before_training, :after_training, :before_iteration, :after_iteration] and
             is_atom(name) do
    %__MODULE__{event: event, fun: fun, name: name, init_state: init_state}
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
          iteration: i
        } = state
      ) do
    lr = if is_list(learning_rates), do: Enum.at(learning_rates, i), else: learning_rates.(i)
    boostr = Exgboost.Booster.set_params(bst, learning_rate: lr)
    {:cont, %{state | booster: boostr}}
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
          meta_vars:
            %{
              early_stop: %{
                best: best,
                patience: patience,
                target_metric: target_metric,
                target_eval: target_eval,
                mode: mode,
                since_last_improvement: since_last_improvement
              }
            } = meta_vars,
          metrics: metrics
        } = state
      ) do
    unless Map.has_key?(metrics, target_eval) do
      raise ArgumentError,
            "target eval_set #{inspect(target_eval)} not found in metrics #{inspect(metrics)}"
    end

    unless Map.has_key?(metrics[target_eval], target_metric) do
      raise ArgumentError,
            "target metric #{inspect(target_metric)} not found in metrics #{inspect(metrics)}"
    end

    prev_criteria_value = best

    cur_criteria_value = metrics[target_eval][target_metric]

    improved? =
      case mode do
        :min ->
          prev_criteria_value == nil or
            cur_criteria_value < prev_criteria_value

        :max ->
          prev_criteria_value == nil or
            cur_criteria_value > prev_criteria_value
      end

    over_patience? = since_last_improvement >= patience

    cond do
      improved? ->
        updated_meta_vars =
          meta_vars
          |> put_in([:early_stop, :best], cur_criteria_value)
          |> put_in([:early_stop, :since_last_improvement], 0)

        bst =
          bst
          |> struct(best_iteration: state.iteration, best_score: cur_criteria_value)
          |> Exgboost.Booster.set_attr(
            best_iteration: state.iteration,
            best_score: cur_criteria_value
          )

        {:cont, %{state | meta_vars: updated_meta_vars, booster: bst}}

      not improved? and not over_patience? ->
        updated_meta_vars =
          meta_vars
          |> put_in([:early_stop, :since_last_improvement], since_last_improvement + 1)

        {:cont, %{state | meta_vars: updated_meta_vars}}

      true ->
        updated_meta_vars =
          meta_vars
          |> put_in([:early_stop, :since_last_improvement], since_last_improvement + 1)

        bst = struct(bst, best_iteration: state.iteration, best_score: cur_criteria_value)
        {:halt, %{state | meta_vars: updated_meta_vars, booster: bst}}
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
          meta_vars: %{eval_metrics: %{evals: evals, filter: filter}}
        } = state
      ) do
    metrics =
      Exgboost.Booster.eval_set(bst, evals, iter)
      |> Enum.reduce(%{}, fn {evname, mname, value}, acc ->
        Map.update(acc, evname, %{mname => value}, fn existing ->
          Map.put(existing, mname, value)
        end)
      end)
      |> Map.filter(filter)

    {:cont, %{state | metrics: metrics}}
    {:cont, %{state | metrics: metrics}}
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
          }
        } = state
      ) do
    if period != 0 and rem(iteration, period) == 0 do
      metrics = Map.filter(metrics, filter)
      IO.puts("Iteration #{iteration}: #{inspect(metrics)}")
    end

    {:cont, state}
  end
end
