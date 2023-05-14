defmodule Exgboost.Training do
  @moduledoc false
  alias Exgboost.Booster
  alias Exgboost.DMatrix
  alias Exgboost.Training.{State, Callback}

  def train(%DMatrix{} = dmat, opts \\ []) do
    {booster_params, opts} = Keyword.pop(opts, :params, [])
    # TODO: Find exhaustive list of params to use String.to_existing_atom()

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

    evals_dmats =
      Enum.map(evals, fn {%Nx.Tensor{} = x, %Nx.Tensor{} = y, _name} ->
        DMatrix.from_tensor(x, y)
      end)

    bst = Booster.booster([dmat | evals_dmats], booster_params)

    verbose_eval =
      case Keyword.fetch!(opts, :verbose_eval) do
        true -> 1
        false -> 0
        value -> value
      end

    callbacks = Keyword.fetch!(opts, :callbacks)

    callbacks =
      unless is_nil(opts[:learning_rates]) do
        [
          %Callback{
            event: :before_iteration,
            fun: &Callback.lr_scheduler/1,
            name: :lr_scheduler,
            init_state: %{learning_rates: learning_rates}
          }
          | callbacks
        ]
      else
        callbacks
      end

    callbacks =
      unless opts[:evals] == [] do
        [
          %Callback{
            event: :after_iteration,
            fun: &Callback.eval_metrics/1,
            name: :eval_metrics,
            init_state: %{evals: evals, filter: fn _, _ -> true end}
          }
          | callbacks
        ]
      else
        callbacks
      end

    callbacks =
      unless verbose_eval == 0 do
        [
          %Callback{
            event: :after_iteration,
            fun: &Callback.monitor_metrics/1,
            name: :monitor_metrics,
            init_state: %{period: verbose_eval, filter: fn _, _ -> true end}
          }
          | callbacks
        ]
      else
        callbacks
      end

    callbacks =
      unless is_nil(opts[:early_stopping_rounds]) do
        unless opts[:evals] == [] do
          [{target_eval, _metric, _value} | _tail] = Enum.reverse(opts[:evals])

          [
            %Callback{
              event: :after_iteration,
              fun: &Callback.early_stop/1,
              name: :early_stop,
              init_state: %{
                patience: opts[:early_stopping_rounds],
                best: nil,
                since_last_improvement: 0,
                mode: :min,
                target_eval: target_eval,
                # TODO: Get this from the Booster
                target_metric: "rmse"
              }
            }
            | callbacks
          ]
        else
          raise ArgumentError, "early_stopping_rounds requires at least one evaluation set"
        end
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
