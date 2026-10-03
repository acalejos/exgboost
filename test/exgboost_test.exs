defmodule EXGBoostTest do
  alias EXGBoost.DMatrix
  alias EXGBoost.Booster
  use ExUnit.Case, async: true

  doctest EXGBoost
  doctest EXGBoost.ArrayInterface

  setup do
    %{key: Nx.Random.key(42)}
  end

  test "small tensor predictions remain stable under GC pressure" do
    training_x =
      Nx.tensor(
        [
          [0.0, 0.0, 0.0, 0.0],
          [0.0, 0.0, 1.0, 1.0],
          [0.0, 1.0, 0.0, 1.0],
          [0.0, 1.0, 1.0, 0.0],
          [1.0, 0.0, 0.0, 1.0],
          [1.0, 0.0, 1.0, 0.0],
          [1.0, 1.0, 0.0, 0.0],
          [1.0, 1.0, 1.0, 1.0]
        ],
        type: {:f, 32}
      )

    training_y =
      Nx.tensor(
        [0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0],
        type: {:f, 32}
      )

    booster =
      EXGBoost.train(
        training_x,
        training_y,
        num_boost_rounds: 10,
        tree_method: :hist,
        objective: :reg_squarederror,
        seed: 0,
        verbose_eval: false
      )

    sample =
      Nx.tensor(
        [[1.0, 0.0, 1.0, 0.0]],
        type: {:f, 32}
      )

    baseline =
      EXGBoost.inplace_predict(
        booster,
        sample,
        validate_features: false
      )

    for iteration <- 1..100 do
      # Create heap pressure before forcing collection.
      _pressure =
        for _ <- 1..1_000 do
          :crypto.strong_rand_bytes(128)
        end

      :erlang.garbage_collect(self())

      prediction =
        EXGBoost.inplace_predict(
          booster,
          sample,
          validate_features: false
        )

      assert Nx.all_close(prediction, baseline),
             "prediction changed on iteration #{iteration}"
    end
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

    {_indptr, _data} = DMatrix.get_quantile_cut(dmat)
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

  test "predict matches inplace_predict", context do
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

  test "predict is stable across repeated calls", context do
    nrows = 12
    ncols = 5
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: 25,
        tree_method: :hist,
        eval_metric: :rmse
      )

    first_preds = EXGBoost.predict(booster, x)
    second_preds = EXGBoost.predict(booster, x)
    third_preds = EXGBoost.predict(booster, x)

    assert Nx.all_close(first_preds, second_preds)
    assert Nx.all_close(first_preds, third_preds)
    assert Nx.all_close(second_preds, third_preds)
  end

  test "predict first call matches subsequent confidence values", context do
    nrows = 30
    ncols = 5
    {x, new_key} = Nx.Random.normal(context.key, 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: 30,
        tree_method: :hist,
        eval_metric: :rmse
      )

    sample = Nx.slice_along_axis(x, 0, 1, axis: 0)

    [baseline_confidence] =
      EXGBoost.predict(booster, sample)
      |> Nx.to_flat_list()

    for i <- 1..10 do
      [confidence] =
        EXGBoost.predict(booster, sample)
        |> Nx.to_flat_list()

      assert_in_delta confidence,
                      baseline_confidence,
                      1.0e-9,
                      "Expected confidence to match baseline #{baseline_confidence}, got #{confidence} for iteration #{i}"
    end
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

    # If no eval metric is provided, the default metric is used. If the default
    # metric is disabled, an error is raised.
    assert_raise ArgumentError,
                 fn ->
                   ExUnit.CaptureIO.with_io(fn ->
                     EXGBoost.train(x, y,
                       disable_default_eval_metric: true,
                       num_boost_rounds: 10,
                       early_stopping_rounds: 1,
                       evals: [{x, y, "validation"}],
                       tree_method: :hist
                     )
                   end)
                 end
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

    assert %{"learner" => _learner, "version" => _version} =
             "test.json" |> File.read!() |> Jason.decode!()

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
    assert %{"learner" => _learner, "version" => _version} = Jason.decode!(buffer)

    bst = EXGBoost.load_model(buffer)
    assert is_struct(bst, EXGBoost.Booster)
  end

  test "load_model accepts legacy serialized snapshots", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(new_key, 0, 1, shape: {nrows})

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: 2,
        tree_method: :hist,
        eval_metric: :rmse
      )

    snapshot =
      EXGBoost.NIF.booster_serialize_to_buffer(booster.ref)
      |> EXGBoost.Internal.unwrap!()

    assert %EXGBoost.Booster{} = EXGBoost.load_model(snapshot)
  end

  test "boost trains with custom gradient and Hessian" do
    x = Nx.tensor([[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], type: {:f, 32})
    y = Nx.tensor([0.0, 1.0, 0.0], type: {:f, 32})
    dmatrix = DMatrix.from_tensor(x, y, format: :dense)
    booster = Booster.booster(dmatrix, tree_method: :hist)
    gradient = Nx.tensor([0.1, -0.2, 0.1], type: {:f, 32})
    hessian = Nx.tensor([1.0, 1.0, 1.0], type: {:f, 32})

    assert :ok = Booster.boost(booster, dmatrix, gradient, hessian)
    assert Booster.get_boosted_rounds(booster) == 1
  end

  test "load_model accepts model artifacts produced by dump_weights", context do
    nrows = :rand.uniform(10)
    ncols = :rand.uniform(10)
    {x, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows, ncols})
    {y, _new_key} = Nx.Random.normal(context[:key], 0, 1, shape: {nrows})

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: 10,
        tree_method: :hist,
        eval_metric: :rmse
      )

    buffer = EXGBoost.dump_weights(booster)
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

    # Test that get_tensor reconstructs the tensor from the stored binary
    assert EXGBoost.ArrayInterface.get_tensor(array_interface) == tensor
  end

  test "array interface from_map ignores optional keys" do
    arr_int =
      EXGBoost.ArrayInterface.from_map(%{
        "typestr" => "<f4",
        "shape" => [2, 2],
        # Address is ignored, only readonly is extracted
        "data" => [123, true],
        "version" => 3,
        "strides" => nil,
        "descr" => [["", "<f4"]]
      })

    assert arr_int.typestr == "<f4"
    assert arr_int.shape == {2, 2}
    # Address field has been removed - we no longer store pointer addresses
    assert arr_int.readonly == true
    assert arr_int.version == 3
  end

  test "array interface get_tensor raises on missing binary" do
    assert_raise ArgumentError, ~r/Cannot reconstruct tensor/, fn ->
      EXGBoost.ArrayInterface.get_tensor(%EXGBoost.ArrayInterface{
        typestr: "<f4",
        shape: {1},
        readonly: true,
        binary: nil
      })
    end
  end

  test "array interface parse_typestr validates format" do
    # Valid typestrs should work (non-bang version returns tuples)
    assert {:ok, {:s, 64}} = EXGBoost.ArrayInterface.parse_typestr("<i8")
    assert {:ok, {:u, 32}} = EXGBoost.ArrayInterface.parse_typestr("<u4")
    assert {:ok, {:f, 32}} = EXGBoost.ArrayInterface.parse_typestr("<f4")
    assert {:ok, {:f, 64}} = EXGBoost.ArrayInterface.parse_typestr("<f8")
    assert {:ok, {:c, 128}} = EXGBoost.ArrayInterface.parse_typestr("<c16")
    assert {:ok, {:s, 8}} = EXGBoost.ArrayInterface.parse_typestr("|i1")
    assert {:ok, {:u, 8}} = EXGBoost.ArrayInterface.parse_typestr("|u1")

    # Bang version returns values directly
    assert {:s, 64} = EXGBoost.ArrayInterface.parse_typestr!("<i8")
    assert {:f, 32} = EXGBoost.ArrayInterface.parse_typestr!("<f4")

    # Big-endian should be rejected
    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr(">f4")
    assert reason =~ ~r/(big-endian|unsupported)/i

    # Byte-order-independent marker (|) only valid for single-byte types
    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr("|i4")
    assert reason =~ ~r/(byte-order-independent|multi-byte)/i

    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr("|f8")
    assert reason =~ ~r/(byte-order-independent|multi-byte)/i

    # Non-bang version returns errors
    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr("<x4")
    assert reason =~ "Unsupported typestr type code"

    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr("<fABC")
    assert reason =~ "Invalid byte count"

    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr("<f")
    assert reason =~ "Invalid typestr"

    assert {:error, reason} = EXGBoost.ArrayInterface.parse_typestr("")
    assert reason =~ "Invalid typestr"

    # Bang version raises on errors
    assert_raise ArgumentError, ~r/Unsupported typestr type code \"x\" in \"<x4\"/, fn ->
      EXGBoost.ArrayInterface.parse_typestr!("<x4")
    end

    assert_raise ArgumentError, ~r/Invalid byte count/, fn ->
      EXGBoost.ArrayInterface.parse_typestr!("<fABC")
    end

    assert_raise ArgumentError, ~r/Invalid typestr/, fn ->
      EXGBoost.ArrayInterface.parse_typestr!("<f")
    end

    assert_raise ArgumentError, ~r/Invalid typestr/, fn ->
      EXGBoost.ArrayInterface.parse_typestr!("")
    end
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
