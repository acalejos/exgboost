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
end
