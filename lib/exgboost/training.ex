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

    defaults =
      default_callbacks(bst, learning_rates, verbose_eval, evals_dmats, early_stopping_rounds)

    callbacks =
      Enum.map(callbacks ++ defaults, fn %Callback{fun: fun} = callback ->
        %{callback | fun: fn state -> state |> fun.() |> State.validate!() end}
      end)

    # Validate callbacks and ensure all names are unique.
    Enum.each(callbacks, &Callback.validate!/1)
    name_counts = Enum.frequencies_by(callbacks, & &1.name)

    if Enum.any?(name_counts, &(elem(&1, 1) > 1)) do
      str = name_counts |> Enum.sort() |> Enum.map_join("\n\n", &"  * #{inspect(&1)}")
      raise ArgumentError, "Found duplicate callback names.\n\nName counts:\n\n#{str}\n"
    end

    state = %State{
      booster: bst,
      iteration: 0,
      max_iteration: num_boost_rounds,
      meta_vars: Map.new(callbacks, &{&1.name, &1.init_state})
    }

    callbacks = Enum.group_by(callbacks, & &1.event, & &1.fun)

    state =
      state
      |> run_callbacks(callbacks, :before_training)
      |> run_training(callbacks, dmat, objective)
      |> run_callbacks(callbacks, :after_training)

    state.booster
  end

  defp run_callbacks(%{status: :halt} = state, _callbacks, _event), do: state

  defp run_callbacks(%{status: :cont} = state, callbacks, event) do
    Enum.reduce_while(callbacks[event] || [], state, fn callback, state ->
      state = callback.(state)
      {state.status, state}
    end)
  end

  defp run_training(%{status: :halt} = state, _callbacks, _dmat, _objective), do: state

  defp run_training(%{status: :cont} = state, callbacks, dmat, objective) do
    Enum.reduce_while(1..state.max_iteration, state, fn iter, state ->
      state =
        state
        |> run_callbacks(callbacks, :before_iteration)
        |> run_iteration(dmat, iter, objective)
        |> run_callbacks(callbacks, :after_iteration)

      {state.status, state}
    end)
  end

  defp run_iteration(%{status: :halt} = state, _dmat, _iter, _objective), do: state

  defp run_iteration(%{status: :cont} = state, dmat, iter, objective) do
    :ok = Booster.update(state.booster, dmat, iter, objective)
    %{state | iteration: iter}
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

        %{"learner" => %{"metrics" => metrics, "default_metric" => default_metric}} =
          EXGBoost.dump_config(bst) |> Jason.decode!()

        metric_name =
          cond do
            Enum.empty?(metrics) && opts[:disable_default_eval_metric] ->
              raise ArgumentError,
                    "`:early_stopping_rounds` requires at least one evaluation set. This means you have likely set `disable_default_eval_metric: true` and have not set any explicit evalutation metrics. Please supply at least one metric in the `:eval_metric` option or set `disable_default_eval_metric: false` (default option)"

            Enum.empty?(metrics) ->
              default_metric

            true ->
              metrics |> Enum.reverse() |> hd() |> Map.fetch!("name")
          end

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
