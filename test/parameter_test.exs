defmodule ParameterTest do
  use ExUnit.Case, async: true
  alias EXGBoost.Booster

  setup do
    {:ok, [key: Nx.Random.key(42)]}
  end

  test "tree booster", context do
    num_class = 10
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})

    {y, _key} =
      Nx.Random.choice(context[:key], Nx.tensor(0..(num_class - 1) |> Enum.to_list()),
        samples: nrows
      )

    num_boost_round = 10

    params = [
      num_boost_rounds: num_boost_round,
      tree_method: :hist,
      obj: :multi_softprob,
      num_class: num_class,
      eval_metric: [
        :rmse,
        :rmsle,
        :mae,
        :mape,
        :logloss,
        :error,
        :auc,
        :merror,
        :mlogloss,
        :gamma_nloglik,
        :inv_map,
        {:tweedie_nloglik, 1.5},
        {:error, 0.2},
        {:ndcg, 3},
        {:map, 2},
        {:inv_ndcg, 3}
      ],
      max_depth: 3,
      eta: 0.3,
      gamma: 0.1,
      min_child_weight: 1,
      subsample: 0.8,
      colsample_by: [tree: 0.8, node: 0.8, level: 0.8],
      lambda: 1,
      alpha: 0,
      grow_policy: :lossguide,
      max_leaves: 0,
      max_bin: 128,
      predictor: :cpu_predictor,
      num_parallel_tree: 1,
      monotone_constraints: [],
      interaction_constraints: []
    ]

    booster = EXGBoost.train(x, y, params)
    assert Booster.get_boosted_rounds(booster) == num_boost_round

    assert_raise NimbleOptions.ValidationError, fn -> EXGBoost.train(x, y, eta: 2) end

    assert_raise NimbleOptions.ValidationError, fn ->
      EXGBoost.train(x, y, updater: [:grow_colmakerm, :grow_histmakerm])
    end

    assert_raise NimbleOptions.ValidationError, fn ->
      EXGBoost.train(x, y, colsample_by: [nottree: 1])
    end
  end

  test "linear booster", context do
    num_class = 10
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})

    {y, _key} =
      Nx.Random.choice(context[:key], Nx.tensor(0..(num_class - 1) |> Enum.to_list()),
        samples: nrows
      )

    num_boost_round = 10

    params = [
      booster: :gblinear,
      num_boost_rounds: num_boost_round,
      lambda: 0.1,
      alpha: 0.1,
      updater: :coord_descent,
      feature_selector: :greedy,
      top_k: 1
    ]

    booster = EXGBoost.train(x, y, params)
    assert Booster.get_boosted_rounds(booster) == num_boost_round

    params = [
      booster: :gblinear,
      num_boost_rounds: num_boost_round,
      lambda: 0.1,
      alpha: 0.1,
      updater: :shotgun,
      feature_selector: :shuffle,
      top_k: 1
    ]

    booster = EXGBoost.train(x, y, params)
    assert Booster.get_boosted_rounds(booster) == num_boost_round

    # TODO Right now this is an ArgumentError, but it should be a NimbleOptions.ValidationError
    assert_raise ArgumentError, fn ->
      EXGBoost.train(x, y, booster: :gblinear, updater: :shotgun, feature_selector: :greedy)
    end
  end

  test "dart booster", context do
    num_class = 10
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})

    {y, _key} =
      Nx.Random.choice(context[:key], Nx.tensor(0..(num_class - 1) |> Enum.to_list()),
        samples: nrows
      )

    num_boost_round = 10

    params = [
      booster: :dart,
      num_boost_rounds: num_boost_round,
      tree_method: :hist,
      obj: :multi_softprob,
      num_class: num_class,
      eval_metric: [
        :rmse,
        :rmsle,
        :mae,
        :mape,
        :logloss,
        :error,
        :auc,
        :merror,
        :mlogloss,
        :gamma_nloglik,
        :inv_map,
        {:tweedie_nloglik, 1.5},
        {:error, 0.2},
        {:ndcg, 3},
        {:map, 2},
        {:inv_ndcg, 3}
      ],
      max_depth: 3,
      eta: 0.3,
      gamma: 0.1,
      min_child_weight: 1,
      subsample: 0.8,
      colsample_by: [tree: 0.8, node: 0.8, level: 0.8],
      lambda: 1,
      alpha: 0,
      grow_policy: :lossguide,
      max_leaves: 0,
      max_bin: 128,
      predictor: :cpu_predictor,
      num_parallel_tree: 1,
      monotone_constraints: [],
      interaction_constraints: [],
      rate_drop: 0.2,
      one_drop: 1
    ]

    booster = EXGBoost.train(x, y, params)
    assert Booster.get_boosted_rounds(booster) == num_boost_round

    assert_raise NimbleOptions.ValidationError, fn ->
      EXGBoost.train(x, y, booster: :dart, eta: 1.5)
    end

    assert_raise NimbleOptions.ValidationError, fn ->
      EXGBoost.train(x, y, booster: :dart, max_depth: -1)
    end

    assert_raise NimbleOptions.ValidationError, fn ->
      EXGBoost.train(x, y, booster: :dart, rate_drop: 2)
    end
  end
end
