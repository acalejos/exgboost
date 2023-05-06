defmodule ExgboostTest do
  use ExUnit.Case, async: true
  doctest Exgboost

  setup do
    {:ok, [key: Nx.Random.key(42)]}
  end

  test "dmatrix_from_list", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {tensor, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    in_list = tensor |> Nx.to_list()
    dmatrix = Exgboost.dmatrix(in_list)
    assert dmatrix["rows"] == nrows
    assert dmatrix["cols"] == ncols
    assert dmatrix["non_missing"] == nrows * ncols
    assert dmatrix["feature_names"] == []
    assert dmatrix["feature_types"] == []
    assert dmatrix["group"] == []

    {_indptr, _indices, data} = dmatrix["data"]
    assert length(data) == nrows * ncols
  end

  test "dmatrix_from_tensor", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {tensor, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    dmatrix = Exgboost.dmatrix(tensor)
    assert dmatrix["rows"] == nrows
    assert dmatrix["cols"] == ncols
    assert dmatrix["non_missing"] == nrows * ncols
    assert dmatrix["feature_names"] == []
    assert dmatrix["feature_types"] == []
    assert dmatrix["group"] == []

    {_indptr, _indices, data} = dmatrix["data"]
    assert length(data) == nrows * ncols
  end

  test "train_booster", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    dtrain = Exgboost.dmatrix(x, y)
    num_boost_round = 10
    params = %{tree_method: "hist"}
    booster = Exgboost.train(dtrain, num_boost_rounds: num_boost_round, params: params)
    assert booster["boosted_rounds"] == num_boost_round
  end
end
