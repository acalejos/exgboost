defmodule EXGBoostTest do
  alias EXGBoost.DMatrix
  alias EXGBoost.Booster
  use ExUnit.Case, async: true
  doctest EXGBoost

  setup do
    %{key: Nx.Random.key(42)}
  end

  test "dmatrix_from_tensor", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {tensor, _new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
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
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})
    num_boost_round = 10
    booster = EXGBoost.train(x, y, num_boost_rounds: num_boost_round, tree_method: :hist)
    assert Booster.get_boosted_rounds(booster) == num_boost_round
  end

  test "quantile cut", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})
    num_boost_round = 10
    dmat = DMatrix.from_tensor(x, y, format: :dense)

    _booster =
      EXGBoost.Training.train(dmat, num_boost_rounds: num_boost_round, tree_method: :hist)

    {indptr, data} = DMatrix.get_quantile_cut(dmat)
  end

  test "booster params" do
    x = Nx.tensor([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
    y = Nx.tensor([0, 1, 2])
    num_boost_round = 10

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: num_boost_round,
        tree_method: :hist,
        obj: :multi_softprob,
        num_class: 3
      )

    assert Booster.get_boosted_rounds(booster) == num_boost_round
  end

  test "train with container" do
    x = {Nx.tensor([[1, 2, 3], [4, 5, 6], [7, 8, 9]])}
    y = {Nx.tensor([0, 1, 2])}
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
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})
    num_boost_round = 10
    booster = EXGBoost.train(x, y, num_boost_rounds: num_boost_round, tree_method: :hist)
    dmat_preds = EXGBoost.predict(booster, x)
    inplace_preds_no_proxy = EXGBoost.inplace_predict(booster, x)
    # TODO: Test inplace_predict with proxy
    # inplace_preds_with_proxy = EXGBoost.inplace_predict(booster, x, base_margin: true)
    assert dmat_preds.shape == y.shape
    assert inplace_preds_no_proxy.shape == y.shape
  end

  test "predict with container", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})
    num_boost_round = 10
    booster = EXGBoost.train({x}, {y}, num_boost_rounds: num_boost_round, tree_method: :hist)
    dmat_preds = EXGBoost.predict(booster, {x})
    inplace_preds_no_proxy = EXGBoost.inplace_predict(booster, {x})
    # TODO: Test inplace_predict with proxy
    # inplace_preds_with_proxy = EXGBoost.inplace_predict(booster, x, base_margin: true)
    assert dmat_preds.shape == y.shape
    assert inplace_preds_no_proxy.shape == y.shape
  end

  test "train with learning rates", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})
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
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})

    {booster, _} =
      ExUnit.CaptureIO.with_io(fn ->
        EXGBoost.train(x, y,
          num_boost_rounds: 10,
          early_stopping_rounds: 1,
          evals: [{x, y, "validation"}],
          tree_method: :hist,
          eval_metric: [:rmse, :logloss]
        )
      end)

    refute is_nil(booster.best_iteration)
    refute is_nil(booster.best_score)
  end

  test "eval with multiple metrics", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})
    num_boost_round = 10

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: num_boost_round,
        tree_method: :hist,
        eval_metric: :rmse
      )

    dmat = DMatrix.from_tensor(x, y, format: :dense)
    [{_ev_name, metric_name, _metric_value}] = Booster.eval(booster, dmat)

    assert metric_name == "rmse"

    Booster.set_params(booster, eval_metric: :logloss)

    metric_results = Booster.eval(booster, dmat)

    assert length(metric_results) == 2
  end

  test "save and load model to and from file", context do
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

    EXGBoost.write_model(booster, "test")
    assert File.exists?("test.json")
    bst = EXGBoost.read_model("test.json")
    assert is_struct(bst, EXGBoost.Booster)
    File.rm!("test.json")
  end

  test "save and load weights to and from file", context do
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

    EXGBoost.write_weights(booster, "test")
    assert File.exists?("test.json")
    bst = EXGBoost.read_weights("test.json")
    assert is_struct(bst, EXGBoost.Booster)
    File.rm!("test.json")
  end

  test "save and load config to and from file", context do
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

    EXGBoost.write_config(booster, "test")
    assert File.exists?("test.json")
    bst = EXGBoost.read_config("test.json")
    assert is_struct(bst, EXGBoost.Booster)
    File.rm!("test.json")
  end

  test "serialize and deserialize model to and from buffer", context do
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

    buffer = EXGBoost.dump_model(booster)
    assert is_binary(buffer)
    bst = EXGBoost.load_model(buffer)
    assert is_struct(bst, EXGBoost.Booster)
  end

  test "serialize and deserialize weights to and from buffer", context do
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

    buffer = EXGBoost.dump_weights(booster)
    assert is_binary(buffer)
    bst = EXGBoost.load_weights(buffer)
    assert is_struct(bst, EXGBoost.Booster)
  end

  test "serialize and deserialize config to and from buffer", context do
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

    buffer = EXGBoost.dump_config(booster)
    assert is_binary(buffer)
    config = EXGBoost.load_config(buffer)
    assert is_map(config)
  end

  test "array interface get tensor" do
    tensor = Nx.tensor([[1, 2, 3], [4, 5, 6]])
    array_interface = EXGBoost.ArrayInterface.from_tensor(tensor)
    # Set this to nil so we can test the get_tensor reconstruction
    array_interface = struct(array_interface, tensor: nil)

    assert EXGBoost.ArrayInterface.get_tensor(array_interface) == tensor
  end

  describe "errors" do
    setup %{key: key0} do
      {nrows, ncols} = {10, 10}
      {x, key1} = Nx.Random.normal(key0, 0, 1, shape: {nrows, ncols})
      {y, _key2} = Nx.Random.normal(key1, 0, 1, shape: {nrows})
      %{x: x, y: y}
    end

    test "duplicate callback names result in an error", %{x: x, y: y} do
      # This callback's name is the same as one of the default callbacks.
      custom_callback = EXGBoost.Training.Callback.new(:before_training, & &1, :monitor_metrics)

      assert_raise ArgumentError,
                   """
                   Found duplicate callback names.

                   Name counts:

                     * {:eval_metrics, 1}

                     * {:monitor_metrics, 2}
                   """,
                   fn ->
                     EXGBoost.train(x, y,
                       callbacks: [custom_callback],
                       eval_metric: [:rmse, :logloss],
                       evals: [{x, y, "validation"}]
                     )
                   end
    end

    test "callback with bad function results in helpful error", %{x: x, y: y} do
      bad_fun = fn state -> %{state | status: :bad_status} end
      bad_callback = EXGBoost.Training.Callback.new(:before_training, bad_fun, :bad_callback)

      assert_raise ArgumentError,
                   "`status` must be `:cont` or `:halt`, found: `:bad_status`.",
                   fn -> EXGBoost.train(x, y, callbacks: [bad_callback]) end
    end
  end
end
