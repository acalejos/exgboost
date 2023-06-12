defmodule EXGBoostTest do
  use ExUnit.Case, async: true

  setup do
    {x, y} = Scidata.Iris.download()
    data = Enum.zip(x, y) |> Enum.shuffle()
    {train, test} = Enum.split(data, ceil(length(data) * 0.8))
    {x_train, y_train} = Enum.unzip(train)
    {x_test, y_test} = Enum.unzip(test)

    x_train = Nx.tensor(x_train)
    y_train = Nx.tensor(y_train)

    x_test = Nx.tensor(x_test)
    y_test = Nx.tensor(y_test)

    %{
      x_train: x_train,
      y_train: y_train,
      x_test: x_test,
      y_test: y_test
    }
  end

  test "protocol implementation", context do
    booster =
      EXGBoost.train(context.x_train, context.y_train, num_class: 3, objective: :multi_softprob)

    trees = DecisionTree.trees(booster)

    trees_params =
      EXGBoost.dump_weights(booster)
      |> Jason.decode!()
      |> get_in(["learner", "gradient_booster", "model", "trees"])

    Enum.each(Enum.zip(trees, trees_params), fn {tree, tree_param} ->
      assert length(Mockingjay.Tree.bfs(tree)) ==
               String.to_integer(get_in(tree_param, ["tree_param", "num_nodes"]))
    end)

    assert is_list(trees)
    assert is_struct(hd(trees), Mockingjay.Tree)
    assert DecisionTree.num_classes(booster) == 3
    assert DecisionTree.num_features(booster) == 4
    assert DecisionTree.output_type(booster) == :classification
  end

  test "compiles", context do
    booster =
      EXGBoost.train(context.x_train, context.y_train, num_class: 3, objective: :multi_softprob)

    compiled_predict = EXGBoost.compile(booster)
    preds1 = EXGBoost.predict(booster, context.x_train) |> Nx.argmax(axis: -1)
    acc1 = Scholar.Metrics.accuracy(context.y_train, preds1)

    preds2 =
      compiled_predict.(context.x_train)
      |> Nx.slice_along_axis(0, 3, axis: 0)
      |> IO.inspect()
      |> Nx.argmax(axis: 0)
      |> IO.inspect()

    acc2 = Scholar.Metrics.accuracy(context.y_train, preds2)
    assert preds1 == preds2
  end
end
