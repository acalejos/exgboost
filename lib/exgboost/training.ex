defmodule Exgboost.Training do
  @moduledoc false
  alias Exgboost.Booster
  alias Exgboost.DMatrix

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
        learning_rates: nil
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
      Keyword.validate!(callbacks,
        before_iteration: [],
        after_iteration: [],
        before_training: [],
        after_training: []
      )

    verbose_eval =
      case Keyword.fetch!(opts, :verbose_eval) do
        true -> 1
        false -> 0
        value -> value
      end

    start_iteration = 0
    num_boost_rounds = Keyword.fetch!(opts, :num_boost_rounds)

    lr_scheduler =
      if not is_nil(learning_rates) do
        fn boostr, i ->
          lr =
            if is_list(learning_rates), do: Enum.at(learning_rates, i), else: learning_rates.(i)

          Booster.set_params(boostr, learning_rate: lr)
          boostr
        end
      else
        fn boostr, _i -> boostr end
      end

    {_current, callbacks} =
      Keyword.get_and_update(callbacks, :before_iteration, fn l -> {l, [lr_scheduler | l]} end)

    bst = Enum.reduce(callbacks[:before_training], bst, fn callback, acc -> callback.(acc) end)

    bst =
      for i <- start_iteration..(num_boost_rounds - 1) do
        bst =
          Enum.reduce(callbacks[:before_iteration], bst, fn callback, acc -> callback.(acc, i) end)

        Booster.update(bst, dmat, i, objective)

        Enum.reduce(callbacks[:after_iteration], bst, fn callback, acc ->
          callback.(acc, i)
        end)
      end

    Enum.reduce(callbacks[:after_training], bst, fn callback, acc -> callback.(acc) end)
  end
end

defmodule Exgboost.CVPack do
  @moduledoc false
  @type t :: %__MODULE__{
          dtrain: DMatrix.t(),
          dtest: DMatrix.t(),
          watchlist: [{DMatrix.t(), String.t()}],
          bst: Booster.t()
        }
  alias Exgboost.Booster
  alias Exgboost.DMatrix
  @enforce_keys [:dtrain, :dtest, :watchlist, :bst]
  defstruct [:dtrain, :dtest, :watchlist, :bst]

  def new(%DMatrix{} = dtrain, %DMatrix{} = dtest, opts \\ []) do
    watchlist = [{dtrain, "train"}, {dtest, "test"}]
    bst = Booster.booster([dtrain, dtest], opts)
    struct(CVPack, dtrain: dtrain, dtest: dtest, watchlist: watchlist, bst: bst)
  end

  def eval(cvpack, iteration, opts \\ []) do
    Booster.eval_set(cvpack.bst, cvpack.watchlist, iteration, opts)
  end

  def update(cvpack, iteration, opts \\ []) do
    opts = Keyword.validate!(opts, fobj: nil)
    fobj = Keyword.fetch!(opts, :fobj)
    Booster.update(cvpack.bst, cvpack.dtrain, iteration, fobj)
  end
end

defmodule Exgboost.PackedBooster do
  alias Exgboost.CVPack
  defstruct [:cvfolds]

  def new(cvfolds) do
    struct(PackedBooster, cvfolds: cvfolds)
  end

  def eval(
        packed_booster,
        iteration,
        opts \\ []
      ) do
    Enum.map(packed_booster.cvfolds, fn fold -> CVPack.eval(fold, iteration, opts) end)
  end

  def update(packed_booster, iteration, opts \\ []) do
    Enum.each(packed_booster.cvfolds, fn fold ->
      fold.update(iteration, opts)
    end)
  end

  def set_attr(packed_booster, attr \\ []) do
    Enum.each(packed_booster.cvfolds, fn fold -> Booster.set_attr(fold.bst, attr) end)
  end

  def attr(packed_booster, key) do
    List.first(packed_booster.cvfolds).bst |> Booster.attr(key)
  end

  def set_param(packed_booster, params \\ []) do
    Enum.each(packed_booster.cvfolds, fn fold -> Booster.set_param(fold.bst, params) end)
  end

  def num_boosted_rounds(packed_booster) do
    List.first(packed_booster.cvfolds).bst |> Booster.get_boosted_rounds()
  end

  def best_iteration(packed_booster) do
    List.first(packed_booster.cvfolds).bst
    |> Booster.get_attr("best_iteration")
    |> String.to_integer()
  end

  def best_score(packed_booster) do
    List.first(packed_booster.cvfolds).bst
    |> Booster.get_attr("best_score")
    |> String.to_integer()
  end
end
