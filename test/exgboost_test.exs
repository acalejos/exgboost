defmodule ExgboostTest do
  alias Exgboost.DMatrix
  alias Exgboost.Booster
  use ExUnit.Case, async: true
  doctest Exgboost

  setup do
    {:ok, [key: Nx.Random.key(42)]}
  end

  test "dmatrix_from_tensor", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {tensor, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    dmatrix = Exgboost.DMatrix.from_tensor(tensor, format: :dense)
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
    params = %{tree_method: "hist"}
    booster = Exgboost.train(x, y, num_boost_rounds: num_boost_round, params: params)
    assert Booster.get_boosted_rounds(booster) == num_boost_round
  end

  test "predict", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    params = %{tree_method: "hist"}
    booster = Exgboost.train(x, y, num_boost_rounds: num_boost_round, params: params)
    dmat_preds = Exgboost.predict(booster, x)
    inplace_preds_no_proxy = Exgboost.inplace_predict(booster, x)
    # TODO: Test inplace_predict with proxy
    # inplace_preds_with_proxy = Exgboost.inplace_predict(booster, x, base_margin: true)
    assert dmat_preds.shape == y.shape
    assert inplace_preds_no_proxy.shape == y.shape
  end

  test "train with learning rates", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    params = %{tree_method: "hist"}
    lrs = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
    lrs_fun = fn i -> i / 10 end

    booster =
      Exgboost.train(x, y, num_boost_rounds: num_boost_round, params: params, learning_rates: lrs)

    booster_fun =
      Exgboost.train(x, y,
        num_boost_rounds: num_boost_round,
        params: params,
        learning_rates: lrs_fun
      )
  end

  test "train with early stopping", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    params = %{tree_method: "hist"}

    booster =
      Exgboost.train(x, y,
        num_boost_rounds: num_boost_round,
        params: params,
        early_stopping_rounds: 3
      )

    assert not is_nil(booster.best_iteration)
    assert not is_nil(booster.score)
  end

  test "eval with multiple metrics", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    params = %{tree_method: "hist"}

    booster =
      Exgboost.train(x, y,
        num_boost_rounds: num_boost_round,
        params: params
      )

    dmat = Exgboost.DMatrix.from_tensor(x, y, format: :dense)
    [{ev_name, metric_name, metric_value}] = Exgboost.Booster.eval(booster, dmat)

    assert metric_name == "rmse"

    booster = Exgboost.Booster.set_params(booster, eval_metric: "logloss")

    metric_results = Exgboost.Booster.eval(booster, dmat)
    IO.inspect(metric_results)
    assert length(metric_results) == 2
  end
end
