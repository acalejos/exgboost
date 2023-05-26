defmodule EXGBoostTest do
  alias EXGBoost.DMatrix
  alias EXGBoost.Booster
  use ExUnit.Case, async: true
  doctest EXGBoost

  setup do
    {:ok, [key: Nx.Random.key(42)]}
  end

  test "dmatrix_from_tensor", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {tensor, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    dmatrix = EXGBoost.DMatrix.from_tensor(tensor, format: :dense)
    assert DMatrix.get_num_rows(dmatrix) == nrows
    assert DMatrix.get_num_cols(dmatrix) == ncols
    assert DMatrix.get_num_non_missing(dmatrix) == nrows * ncols
    assert DMatrix.get_feature_names(dmatrix) == []
    assert DMatrix.get_feature_types(dmatrix) == []
    assert DMatrix.get_group(dmatrix) == []

    {_indptr, _indices, data} = DMatrix.get_data(dmatrix)
    assert length(data) == nrows * ncols
  end

  test "train_booster", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    booster = EXGBoost.train(x, y, num_boost_rounds: num_boost_round, tree_method: :hist)
    assert Booster.get_boosted_rounds(booster) == num_boost_round
  end

  test "booster params" do
    x = Nx.tensor([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
    y = Nx.tensor([0, 1, 2])
    num_boost_round = 10

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: num_boost_round,
        tree_method: :hist,
        objective: :multi_softprob,
        num_class: 3
      )

    assert Booster.get_boosted_rounds(booster) == num_boost_round
  end

  test "predict", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    booster = EXGBoost.train(x, y, num_boost_rounds: num_boost_round, tree_method: :hist)
    dmat_preds = EXGBoost.predict(booster, x)
    inplace_preds_no_proxy = EXGBoost.inplace_predict(booster, x)
    # TODO: Test inplace_predict with proxy
    # inplace_preds_with_proxy = EXGBoost.inplace_predict(booster, x, base_margin: true)
    assert dmat_preds.shape == y.shape
    assert inplace_preds_no_proxy.shape == y.shape
  end

  test "train with learning rates", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    lrs = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
    lrs_fun = fn i -> i / 10 end

    EXGBoost.train(x, y,
      num_boost_rounds: num_boost_round,
      tree_method: :hist,
      learning_rates: lrs
    )

    EXGBoost.train(x, y,
      num_boost_rounds: num_boost_round,
      tree_method: :hist,
      learning_rates: lrs_fun
    )
  end

  test "train with early stopping", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: 10,
        early_stopping_rounds: 1,
        evals: [{x, y, "validation"}],
        tree_method: :hist,
        eval_metric: [:rmse, :logloss]
      )

    assert not is_nil(booster.best_iteration)
    assert not is_nil(booster.best_score)
  end

  test "eval with multiple metrics", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: num_boost_round,
        tree_method: :hist,
        eval_metric: :rmse
      )

    dmat = EXGBoost.DMatrix.from_tensor(x, y, format: :dense)
    [{_ev_name, metric_name, _metric_value}] = EXGBoost.Booster.eval(booster, dmat)

    assert metric_name == "rmse"

    EXGBoost.Booster.set_params(booster, eval_metric: :logloss)

    metric_results = EXGBoost.Booster.eval(booster, dmat)

    assert length(metric_results) == 2
  end
end
