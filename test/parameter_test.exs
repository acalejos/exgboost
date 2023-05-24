defmodule ParameterTest do
  use ExUnit.Case, async: true
  alias EXGBoost.Booster

  setup do
    {:ok, [key: Nx.Random.key(42)]}
  end

  test "tree booster with good params", context do
    num_class = 10
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})

    {y, _key} =
      Nx.Random.choice(context[:key], Nx.tensor(1..num_class |> Enum.to_list()), samples: nrows)

    num_boost_round = 10

    params = [
      num_boost_rounds: num_boost_round,
      tree_method: :hist,
      objective: :multi_softprob,
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
  end
end
