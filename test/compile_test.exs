defmodule EXGBoostTest do
  use ExUnit.Case, async: true
  alias Mockingjay.DecisionTree

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
  end

  test "compiles", context do
    booster =
      EXGBoost.train(context.x_train, context.y_train, num_class: 3, objective: :multi_softprob)

    gemm_predict = EXGBoost.compile(booster, strategy: :gemm)
    tt_predict = EXGBoost.compile(booster, strategy: :tree_traversal)
    ptt_predict = EXGBoost.compile(booster, strategy: :ptt)
    auto_predict = EXGBoost.compile(booster, strategy: :auto)
    # host_jit = EXLA.jit(compiled_predict)

    preds1 =
      EXGBoost.predict(booster, context.x_test)
      |> Nx.argmax(axis: -1)

    preds2 = gemm_predict.(context.x_test) |> Nx.argmax(axis: -1)
    preds3 = tt_predict.(context.x_test) |> Nx.argmax(axis: -1)
    preds4 = ptt_predict.(context.x_test) |> Nx.argmax(axis: -1)
    preds5 = auto_predict.(context.x_test) |> Nx.argmax(axis: -1)

    base_acc =
      Scholar.Metrics.accuracy(context.y_test, preds1)
      |> Nx.to_number()

    gmm_accuracy =
      Scholar.Metrics.accuracy(context.y_test, preds2)
      |> Nx.to_number()

    tt_accuracy =
      Scholar.Metrics.accuracy(context.y_test, preds3)
      |> Nx.to_number()

    ptt_accuracy =
      Scholar.Metrics.accuracy(context.y_test, preds4)
      |> Nx.to_number()

    auto_accuracy =
      Scholar.Metrics.accuracy(context.y_test, preds5)
      |> Nx.to_number()

    assert gmm_accuracy >= base_acc
    assert tt_accuracy >= base_acc
    assert ptt_accuracy >= base_acc
    assert auto_accuracy >= base_acc
  end
end
