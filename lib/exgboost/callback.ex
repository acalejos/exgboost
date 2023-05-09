defprotocol TrainingCallback do
  @moduledoc false
  @type score :: float() | {float(), float()}
  @type scoreList :: [float()] | [{float(), float()}]
  # real type is Union[Booster, CVPack]; need more work
  @type model :: any()
  @type evalsLog :: %{String.t() => %{String.t() => scoreList}}
  @type training_callback :: any()

  @doc """
   Run before training starts.
  """
  @spec before_training(callback :: training_callback(), model :: model) :: model
  def before_training(callback, model)

  @doc """
   Run after training ends.
  """
  @spec after_training(callback :: training_callback(), model :: model) :: model
  def after_training(callback, model)

  @doc """
  Run before each iteration.  Return True when training should stop.
  """
  @spec before_iteration(
          callback :: training_callback(),
          model :: model,
          epoch :: pos_integer(),
          evals_log :: evalsLog
        ) :: bool
  def before_iteration(callback, model, epoch, evals_log)

  @doc """
  Run after each iteration.  Return True when training should stop.
  """
  @spec after_iteration(
          callback :: training_callback(),
          model :: model,
          epoch :: integer(),
          evals_log :: evalsLog
        ) :: bool
  def after_iteration(callback, model, epoch, evals_log)
end

defmodule Exgboost.CallbackContainer do
  @moduledoc false
  alias Exgboost.DMatrix
  alias __MODULE__
  alias Exgboost.Booster, as: B

  @enforce_keys [:callbacks]
  defstruct [
    :callbacks,
    history: %{},
    metric: nil,
    output_margin: true,
    is_cv: false,
    aggregated_cv: nil
  ]

  def new(callbacks, opts \\ []) do
    opts = Keyword.validate!(opts, [:metric, :output_margin, :is_cv])
    args = %{callback: callbacks}
    args = Enum.into(opts, args)

    struct(CallbackContainer, args)
  end

  defimpl Training do
    @impl true
    def before_training(container, model) do
      for c <- container.callbacks do
        model = before_training(c, model)
        msg = "before_training should return the model"

        if container.is_cv do
          if not is_list(model.cvfolds), do: raise(msg)
        else
          if not is_struct(model, Booster), do: raise(msg)
        end

        model
      end
    end

    @impl true
    def after_training(container, model) do
      model =
        for c <- container.callbacks do
          model = after_training(c, model)
          msg = "after_training should return the model"

          if container.is_cv do
            if not is_list(model.cvfolds), do: raise(msg)
          else
            if not is_struct(model, Booster), do: raise(msg)
          end

          model
        end

      if not container.is_cv do
        if Model.get_attr("best_score") do
          best_score = String.to_float(Model.get_attr(model, "best_score"))
          best_iteration = String.to_integer(Model.get_attr(model, "best_iteration"))
          struct(model, best_score: best_score, best_iteration: best_iteration)
        else
          best_iteration = Model.num_boosted_rounds(model) - 1
          Model.set_attr("best_iteration", Integer.to_string(best_iteration))
          struct(model, best_iteration: best_iteration)
        end
      else
        model
      end
    end

    @impl true
    def before_iteration(container, model, epoch, _evals_log) do
      Enum.any?(container.callbacks, fn c ->
        before_iteration(c, model, epoch, container.history)
      end)
    end

    # def after_iteration(
    #       self,
    #       model: _model,
    #       epoch: int,
    #       dtrain: DMatrix,
    #       evals: Optional[List[Tuple[DMatrix, str]]],
    #   ) -> bool:
    #       """Function called after training iteration."""
    #       if self.is_cv:
    #           scores = model.eval(epoch, self.metric, self._output_margin)
    #           scores = _aggcv(scores)
    #           self.aggregated_cv = scores
    #           self._update_history(scores, epoch)
    #       else:
    #           evals = [] if evals is None else evals
    #           for _, name in evals:
    #               assert name.find("-") == -1, "Dataset name should not contain `-`"
    #           score: str = model.eval_set(evals, epoch, self.metric, self._output_margin)
    #           metric_score = _parse_eval_str(score)
    #           self._update_history(metric_score, epoch)
    #       ret = any(c.after_iteration(model, epoch, self.history) for c in self.callbacks)
    #       return ret

    @impl true
    # TODO: FIx this
    def after_iteration(container, model, epoch, evals_log) do
      container =
        if container.is_cv do
          scores = Model.eval(model, epoch, container.metric, container.output_margin)
          # scores = _aggcv(scores)
          container = struct(container, aggregated_cv: scores)
          _update_history(container, scores, epoch)
        else
          evals = []

          evals =
            for {d, name} <- evals_log do
              if String.contains?(name, "-"), do: raise("Dataset name should not contain `-`")
              [{d, name} | evals]
            end

          score = Model.eval_set(model, evals, epoch, container.metric, container.output_margin)
          metric_score = _parse_eval_str(score)
          _update_history(container, metric_score, epoch)
        end

      Enum.any?(container.callbacks, fn c ->
        after_iteration(c, model, epoch, container.history)
      end)
    end
  end

  def _update_history(container, score, epoch) do
    history =
      for d <- score do
        {name, x} =
          case d do
            [name, s] ->
              {name, s}

            [name, s, std] ->
              {name, {s, std}}
          end

        splited_names = String.split(name, "-")
        data_name = List.first(splited_names)
        [_ | metric_name] = splited_names
        metric_name = Enum.join(metric_name, "-")
        x = _allreduce_metric(x)

        history =
          if not Map.has_key?(container.history, data_name) do
            Map.put(container.history, data_name, %{})
          else
            container.history
          end

        container = struct(container, history: history)

        data_history = Map.get(container.history, data_name)

        data_history =
          if not Map.has_key?(data_history, metric_name) do
            Map.put(data_history, metric_name, [])
          else
            data_history
          end

        metric_history = Map.get(data_history, metric_name)

        metric_history =
          if container.is_cv do
            [x | metric_history]
          else
            [x | metric_history]
          end

        data_history = Map.put(data_history, metric_name, metric_history)
        Map.put(container.history, data_name, data_history)
      end

    history
  end
end
