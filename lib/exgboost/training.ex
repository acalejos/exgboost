defmodule EXGBoost.Training do
  @moduledoc false
  alias EXGBoost.Booster
  alias EXGBoost.DMatrix
  alias EXGBoost.Training.{State, Callback}

  @spec train(DMatrix.t(), Keyword.t()) :: Booster.t()
  def train(%DMatrix{} = dmat, opts \\ []) do
    valid_opts = [
      callbacks: [],
      early_stopping_rounds: nil,
      evals: [],
      learning_rates: nil,
      num_boost_rounds: 10,
      obj: nil,
      verbose_eval: true
    ]

    {opts, booster_params} = Keyword.split(opts, Keyword.keys(valid_opts))

    [
      callbacks: callbacks,
      early_stopping_rounds: early_stopping_rounds,
      evals: evals,
      learning_rates: learning_rates,
      num_boost_rounds: num_boost_rounds,
      obj: objective,
      verbose_eval: verbose_eval
    ] = opts |> Keyword.validate!(valid_opts) |> Enum.sort()

    unless is_nil(learning_rates) or is_function(learning_rates, 1) or is_list(learning_rates) do
      raise ArgumentError, "learning_rates must be a function/1 or a list"
    end

    if early_stopping_rounds && evals == [] do
      raise ArgumentError, "early_stopping_rounds requires at least one evaluation set"
    end

    for callback <- callbacks do
      Callback.validate!(callback)
    end

    verbose_eval =
      case verbose_eval do
        true -> 1
        false -> 0
        value -> value
      end

    evals_dmats =
      Enum.map(evals, fn {x, y, name} ->
        {DMatrix.from_tensor(x, y, format: :dense), name}
      end)

    bst =
      Booster.booster(
        [dmat | Enum.map(evals_dmats, fn {dmat, _name} -> dmat end)],
        booster_params
      )

    callbacks =
      callbacks ++
        default_callbacks(bst, learning_rates, verbose_eval, evals_dmats, early_stopping_rounds)

    callbacks = Enum.map(callbacks, &wrap_callback/1)

    state = %State{
      booster: bst,
      iteration: 0,
      max_iteration: num_boost_rounds,
      meta_vars: Map.new(callbacks, &{&1.name, &1.init_state})
    }

    callbacks_by_event = Enum.group_by(callbacks, & &1.event, & &1.fun)

    state = run_callbacks(state, callbacks_by_event, :before_training)

    state =
      if state.status == :halt do
        state
      else
        Enum.reduce_while(1..state.max_iteration, state, fn iter, iter_state ->
          iter_state = run_callbacks(iter_state, callbacks_by_event, :before_iteration)

          iter_state =
            if iter_state.status == :halt do
              iter_state
            else
              :ok = Booster.update(iter_state.booster, dmat, iter, objective)
              run_callbacks(%{iter_state | iteration: iter}, callbacks_by_event, :after_iteration)
            end

          {iter_state.status, iter_state}
        end)
      end

    if state.status == :halt do
      state.booster
    else
      final_state = run_callbacks(state, callbacks_by_event, :after_training)
      final_state.booster
    end
  end

  defp wrap_callback(%Callback{fun: fun} = callback) do
    %{callback | fun: fn state -> state |> fun.() |> State.validate!() end}
  end

  defp run_callbacks(state, callbacks_by_event, event) do
    Enum.reduce_while(callbacks_by_event[event] || [], state, fn callback, state ->
      state = callback.(state)
      {state.status, state}
    end)
  end

  defp default_callbacks(bst, learning_rates, verbose_eval, evals_dmats, early_stopping_rounds) do
    default_callbacks = []

    default_callbacks =
      if learning_rates do
        lr_scheduler = %Callback{
          event: :before_iteration,
          fun: &Callback.lr_scheduler/1,
          name: :lr_scheduler,
          init_state: %{learning_rates: learning_rates}
        }

        [lr_scheduler | default_callbacks]
      else
        default_callbacks
      end

    default_callbacks =
      if verbose_eval != 0 and evals_dmats != [] do
        monitor_metrics = %Callback{
          event: :after_iteration,
          fun: &Callback.monitor_metrics/1,
          name: :monitor_metrics,
          init_state: %{period: verbose_eval, filter: fn {_, _} -> true end}
        }

        [monitor_metrics | default_callbacks]
      else
        default_callbacks
      end

    default_callbacks =
      if early_stopping_rounds && evals_dmats != [] do
        [{_dmat, target_eval} | _tail] = Enum.reverse(evals_dmats)

        # Default to the last metric
        [%{"name" => metric_name} | _tail] =
          EXGBoost.dump_config(bst)
          |> Jason.decode!()
          |> get_in(["learner", "metrics"])
          |> Enum.reverse()

        early_stop = %Callback{
          event: :after_iteration,
          fun: &Callback.early_stop/1,
          name: :early_stop,
          init_state: %{
            patience: early_stopping_rounds,
            best: nil,
            since_last_improvement: 0,
            mode: :min,
            target_eval: target_eval,
            target_metric: metric_name
          }
        }

        [early_stop | default_callbacks]
      else
        default_callbacks
      end

    default_callbacks =
      if evals_dmats != [] do
        eval_metrics = %Callback{
          event: :after_iteration,
          fun: &Callback.eval_metrics/1,
          name: :eval_metrics,
          init_state: %{evals: evals_dmats, filter: fn {_, _} -> true end}
        }

        [eval_metrics | default_callbacks]
      else
        default_callbacks
      end

    default_callbacks
  end
end
