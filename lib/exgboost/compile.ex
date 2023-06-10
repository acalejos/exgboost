defimpl DecisionTree, for: EXGBoost.Booster do
  def trees(booster) do
    model = EXGBoost.dump_weights(booster) |> Jason.decode!()
    trees = get_in(model, ["learner", "learner_model_param", "trees"])
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

  def output_type(booster) do
    model = EXGBoost.dump_weights(booster) |> Jason.decode!()

    num_classes =
      model
      |> get_in(["learner", "learner_model_param", "num_class"])

    if is_nil(num_classes) do
      objective =
        model
        |> get_in(["learner", "objective", "name"])

      case String.split(objective, ":") |> hd do
        type when type in ["reg", "count", "survival", "rank"] ->
          :classification

        type when type in ["multi", "binary"] ->
          :classification

        _ ->
          raise "Could not infer output type from model objective -- unknonwn objective: #{objective}"
      end
    else
      if num_classes == "0", do: :regression, else: :classification
    end
  end

  def condition(booster) do
    model = EXGBoost.dump_weights(booster) |> Jason.decode!()
  end
end
