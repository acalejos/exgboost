defmodule Exgboost.Training do
  @moduledoc false
  alias Exgboost.Booster
  alias Exgboost.DMatrix
  alias Exgboost.Training.{State, Callback}

  def train(%DMatrix{} = dmat, opts \\ []) do
    {booster_opts, opts} = Keyword.pop(opts, :params, %{})
    # TODO: Find exhaustive list of params to use String.to_existing_atom()
    booster_opts = Keyword.new(booster_opts, fn {key, value} -> {key, value} end)

    bst = Exgboost.Booster.booster(dmat, booster_opts)

    opts =
      Keyword.validate!(opts,
        obj: nil,
        num_boost_rounds: 10,
        evals: [],
        verbose_eval: true,
        callbacks: [],
        learning_rates: nil,
        early_stopping_rounds: nil
      )

    learning_rates = Keyword.fetch!(opts, :learning_rates)

    if not is_nil(learning_rates) and
         not (is_function(learning_rates, 1) or is_list(learning_rates)) do
      raise ArgumentError, "learning_rates must be a function/1 or a list"
    end

    objective = Keyword.fetch!(opts, :obj)
    evals = Keyword.fetch!(opts, :evals)
    callbacks = Keyword.fetch!(opts, :callbacks)

    callbacks =
      unless is_nil(opts[:learning_rates]) do
        [
          %Callback{
            event: :before_iteration,
            fun: &lr_scheduler/1,
            name: :lr_scheduler,
            init_state: %{learning_rates: learning_rates}
          }
          | callbacks
        ]
      else
        callbacks
      end

    callbacks =
      unless is_nil(opts[:early_stopping_rounds]) do
        [
          %Callback{
            event: :after_iteration,
            fun: &early_stop/1,
            name: :early_stop,
            init_state: %{
              patience: opts[:early_stopping_rounds],
              best: nil,
              since_last_improvement: 0,
              mode: :min,
              target: :validation_error
            }
          }
          | callbacks
        ]
      else
        callbacks
      end

    default = %{
      before_iteration: [],
      after_iteration: [],
      before_training: [],
      after_training: [],
      init_state: %{}
    }

    env =
      Enum.reduce(callbacks, default, fn %Callback{} = callback, acc ->
        acc =
          case callback.event do
            :before_iteration ->
              %{acc | before_iteration: [callback.fun | acc[:before_iteration]]}

            :after_iteration ->
              %{acc | after_iteration: [callback.fun | acc[:after_iteration]]}

            :before_training ->
              %{acc | before_training: [callback.fun | acc[:before_training]]}

            :after_training ->
              %{acc | after_training: [callback.fun | acc[:after_training]]}

            _ ->
              raise ArgumentError, "Invalid callback: #{inspect(callback)}"
          end

        case callback.name do
          nil -> acc
          name -> put_in(acc[:init_state][name], callback.init_state)
        end
      end)

    verbose_eval =
      case Keyword.fetch!(opts, :verbose_eval) do
        true -> 1
        false -> 0
        value -> value
      end

    start_iteration = 0
    num_boost_rounds = Keyword.fetch!(opts, :num_boost_rounds)

    init_state = %State{
      booster: bst,
      iteration: 0,
      max_iteration: num_boost_rounds,
      meta_vars: env[:init_state]
    }

    {status, state} =
      case run_callbacks(env[:before_training], init_state) do
        {:halt, state} ->
          {:halted, state}

        {:cont, state} ->
          Enum.reduce_while(
            start_iteration..(num_boost_rounds - 1),
            {:cont, state},
            fn iter, {_, iter_state} ->
              # IO.puts("iter state: #{inspect(iter_state)}")
              case run_callbacks(env[:before_iteration], iter_state) do
                {:halt, state} ->
                  {:halt, {:halted, state}}

                {:cont, state} ->
                  Booster.update(state.booster, dmat, iter, objective)

                  case run_callbacks(env[:after_iteration], %{state | booster: bst}) do
                    {:halt, state} ->
                      {:halt, {:halted, state}}

                    {:cont, state} ->
                      {:cont, {:cont, %{state | iteration: state.iteration + 1}}}
                  end
              end
            end
          )
      end

    case status do
      :halted ->
        state.booster

      :cont ->
        {_status, final_state} = run_callbacks(env[:after_training], state)
        final_state.booster
    end
  end

  defp lr_scheduler(
         %State{
           booster: bst,
           meta_vars: %{lr_scheduler: %{learning_rates: learning_rates}},
           iteration: i
         } = state
       ) do
    lr = if is_list(learning_rates), do: Enum.at(learning_rates, i), else: learning_rates.(i)
    boostr = Booster.set_params(bst, learning_rate: lr)
    {:cont, %{state | booster: boostr}}
  end

  # TODO: Ideally this would be generalized like it is in Axon to allow generic monitoring of metrics,
  # but for now we'll just do early stopping
  defp early_stop(
         %State{
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
          |> Booster.set_attr(best_iteration: state.iteration, best_score: cur_criteria_value)

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

  defp run_callbacks(callbacks, state) do
    callbacks
    |> Enum.reduce_while({:cont, state}, fn callback, {_, state} ->
      # IO.puts("callback: #{inspect(callback)}")
      # IO.puts("callback state: #{inspect(state)}")

      case callback.(state) do
        {:cont, %State{} = state} ->
          {:cont, {:cont, state}}

        {:halt, %State{} = state} ->
          {:halt, {:halt, state}}

        invalid ->
          raise ArgumentError,
                "invalid value #{inspect(invalid)} returned from callback" <>
                  " Callback handler must return" <>
                  " a tuple of {status, state} where status is one of :cont," <>
                  " or :halt and state is an updated State struct"
      end
    end)
  end
end
