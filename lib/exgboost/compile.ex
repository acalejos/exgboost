defimpl Mockingjay.DecisionTree, for: EXGBoost.Booster do
  def trees(booster) do
    model = EXGBoost.dump_weights(booster) |> Jason.decode!()
    trees = get_in(model, ["learner", "gradient_booster", "model", "trees"])

    if is_nil(trees) do
      raise "Could not find trees in model"
    end

    trees
    |> Enum.map(fn tree ->
      EXGBoost.Compile.to_tree(tree) |> Mockingjay.Tree.from_map()
    end)
  end

  def num_classes(booster) do
    num_classes =
      EXGBoost.dump_weights(booster)
      |> Jason.decode!()
      |> get_in(["learner", "learner_model_param", "num_class"])

    if is_nil(num_classes) do
      raise "Could not find num_classes in model"
    end

    String.to_integer(num_classes)
  end

  def num_features(booster) do
    model = EXGBoost.dump_weights(booster) |> Jason.decode!()
    num_features = get_in(model, ["learner", "learner_model_param", "num_feature"])

    if is_nil(num_features) do
      raise "Could not find num_features in model"
    end

    String.to_integer(num_features)
  end

  def condition(_booster) do
    :less
  end
end

defmodule EXGBoost.Compile do
  def to_tree(%{} = tree_map) do
    nodes =
      Enum.zip([
        tree_map["left_children"],
        tree_map["right_children"],
        tree_map["split_conditions"],
        tree_map["split_indices"]
      ])

    case nodes do
      [{_left, _right, _threshold, value}] ->
        %{value: value}

      [_root | _rest] ->
        nodes = Enum.with_index(nodes)
        [current | rest] = nodes
        _to_tree(current, rest)

      [] ->
        %{}
    end
  end

  def _to_tree(current, rest) do
    {current, _} = current

    case current do
      {-1, -1, value, _feature_id} ->
        %{
          value: value
        }

      {left_id, right_id, threshold, feature_id} ->
        %{true: [left_next], false: left_rest} =
          Enum.group_by(rest, fn {_elem, index} -> index == left_id end)

        %{true: [right_next], false: right_rest} =
          Enum.group_by(rest, fn {_elem, index} -> index == right_id end)

        %{
          left: _to_tree(left_next, left_rest),
          right: _to_tree(right_next, right_rest),
          value: %{threshold: threshold, feature: feature_id}
        }
    end
  end
end
