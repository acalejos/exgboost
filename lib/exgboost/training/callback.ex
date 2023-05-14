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

  """
  @enforce_keys [:event, :fun]
  defstruct [:event, :fun, :name, :init_state]

  def new(event, fun) do
    new(event, fun, nil, %{})
  end

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
        %Exgboost.Training.State{
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
  A callback that performs early stopping.

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
        %Exgboost.Training.State{
          booster: bst,
          meta_vars:
            %{
              early_stop: %{
                best: best,
                patience: patience,
                target: target,
                mode: mode,
                since_last_improvement: since_last_improvement
              }
            } = meta_vars,
          metrics: metrics
        } = state
      ) do
    unless Map.has_key?(metrics, target) do
      raise ArgumentError,
            "target metric #{inspect(target)} not found in metrics #{inspect(metrics)}"
    end

    prev_criteria_value =
      case best do
        nil -> metrics[target]
        value -> value
      end

    cur_criteria_value = metrics[target]

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

        {:halt, %{state | meta_vars: updated_meta_vars}}
    end
  end
end
