defmodule NifTest do
  use ExUnit.Case, async: true

  import EXGBoost.Internal
  import EXGBoost.ArrayInterface, only: [from_tensor: 1, to_tuple: 1]

  test "exgboost_version" do
    assert EXGBoost.NIF.xgboost_version() |> unwrap!() != :error
  end

  test "unwrap! raises string error for charlist reasons" do
    assert_raise ArgumentError, "boom", fn ->
      unwrap!({:error, ~c"boom"})
    end
  end

  test "build_info" do
    assert EXGBoost.NIF.xgboost_build_info() |> unwrap!() != :error
  end

  test "set_global_config" do
    assert EXGBoost.NIF.set_global_config(~c'{"use_rmm":false,"verbosity":1}') == :ok

    assert EXGBoost.NIF.set_global_config(~c'{"use_rmm":false,"verbosity": true}') ==
             {:error, ~c"Invalid Parameter format for verbosity expect int but value='true'"}
  end

  test "get_global_config" do
    assert EXGBoost.NIF.get_global_config() |> unwrap!() != :error
  end

  test "dmatrix_create_from_uri" do
    config = Jason.encode!(%{uri: "test/data/train.txt?format=libsvm"})
    assert EXGBoost.NIF.dmatrix_create_from_uri(config) |> unwrap!() != :error
  end

  test "dmatrix_create_from_sparse" do
    indptr = Nx.tensor([0, 22])
    ncols = 127

    indices =
      Nx.tensor([
        1,
        9,
        19,
        21,
        24,
        34,
        36,
        39,
        42,
        53,
        56,
        65,
        69,
        77,
        86,
        88,
        92,
        95,
        102,
        106,
        117,
        122
      ])

    data =
      Nx.tensor([
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0
      ])

    indptr_arr_tuple = from_tensor(indptr) |> to_tuple()
    indices_arr_tuple = from_tensor(indices) |> to_tuple()
    data_arr_tuple = from_tensor(data) |> to_tuple()

    assert EXGBoost.NIF.dmatrix_create_from_sparse(
             indptr_arr_tuple,
             indices_arr_tuple,
             data_arr_tuple,
             ncols,
             config(),
             "csr"
           )
           |> unwrap!() !=
             :error

    assert EXGBoost.NIF.dmatrix_create_from_sparse(
             indptr_arr_tuple,
             indices_arr_tuple,
             data_arr_tuple,
             ncols,
             config(),
             "csc"
           )
           |> unwrap!() != :error

    {status, _} =
      EXGBoost.NIF.dmatrix_create_from_sparse(
        indptr_arr_tuple,
        indices_arr_tuple,
        data_arr_tuple,
        ncols,
        config(),
        "csa"
      )

    assert status == :error
  end

  test "dmatrix_create_from_dense" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    arr = from_tensor(mat)

    assert EXGBoost.NIF.dmatrix_create_from_dense(
             to_tuple(arr),
             config()
           )
           |> unwrap!() != :error
  end

  test "dmatrix_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(arr),
        config()
      )
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_set_str_feature_info(dmat, ~c"feature_name", [
             ~c"name",
             ~c"color",
             ~c"length"
           ]) == :ok
  end

  test "dmatrix_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    EXGBoost.NIF.dmatrix_set_str_feature_info(dmat, ~c"feature_name", [
      ~c"name",
      ~c"color",
      ~c"length"
    ])

    assert EXGBoost.NIF.dmatrix_get_str_feature_info(dmat, ~c"feature_name") |> unwrap!()
  end

  test "dmatrix_num_row" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_row(dmat) |> unwrap! == 2
  end

  test "dmatrix_num_col" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_col(dmat) |> unwrap! == 3
  end

  test "dmatrix_num_non_missing" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_non_missing(dmat) |> unwrap! == 6
  end

  test "dmatrix_set_info_from_interface" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)
    labels = Nx.tensor([1.0, 0.0])

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    label_arr = from_tensor(labels)

    assert EXGBoost.NIF.dmatrix_set_info_from_interface(
             dmat,
             ~c"label",
             to_tuple(label_arr)
           ) ==
             :ok

    assert EXGBoost.NIF.dmatrix_set_info_from_interface(
             dmat,
             ~c"unsupported",
             to_tuple(label_arr)
           ) != :ok
  end

  test "dmatrix_save_binary" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)
    labels = Nx.tensor([1.0, 0.0])

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    label_arr = from_tensor(labels)

    EXGBoost.NIF.dmatrix_set_info_from_interface(
      dmat,
      ~c"label",
      to_tuple(label_arr)
    )

    path = Path.join(System.tmp_dir!(), "test.buffer") |> String.to_charlist()
    assert EXGBoost.NIF.dmatrix_save_binary(dmat, path, 1) == :ok
  end

  test "dmatrix_get_float_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)
    weights = Nx.tensor([1.0, 0.0])

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    weights_arr = from_tensor(weights)

    EXGBoost.NIF.dmatrix_set_info_from_interface(
      dmat,
      ~c"feature_weights",
      to_tuple(weights_arr)
    )

    assert EXGBoost.NIF.dmatrix_get_float_info(dmat, ~c"feature_weights") |> unwrap!() ==
             Nx.to_list(weights)
  end

  test "dmatrix_get_data_as_csr" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_get_data_as_csr(dmat, Jason.encode!(%{})) |> unwrap!() != :error
  end

  test "dmatrix_slice" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    # We do this because the C API uses non fixed-width types so we need to know the size they're expecting from int
    c_int_size = EXGBoost.NIF.get_int_size() |> unwrap!()
    tensor_size = c_int_size * 8

    dmatrix =
      EXGBoost.NIF.dmatrix_slice(
        dmat,
        Nx.to_binary(Nx.tensor([0, 1], type: {:s, tensor_size})),
        1
      )
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_row(dmatrix) |> unwrap!() == 2

    {status, _e} =
      EXGBoost.NIF.dmatrix_slice(
        dmat,
        Nx.to_binary(Nx.tensor([0, 1], type: {:s, tensor_size})),
        2
      )

    assert status == :error

    {status, _e} = EXGBoost.NIF.dmatrix_slice(dmat, Nx.to_binary(Nx.tensor([1.5, 1.6])), 2)

    assert status == :error
  end

  test "booster_create" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat2 = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)
    mat2_arr = from_tensor(mat2)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    dmat2 =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat2_arr),
        config()
      )
      |> unwrap!()

    assert EXGBoost.NIF.booster_create([dmat]) |> unwrap!() != :error
    assert EXGBoost.NIF.booster_create([]) |> unwrap!() != :error
    assert EXGBoost.NIF.booster_create([dmat, dmat2]) |> unwrap!() != :error
  end

  test "booster_get_num_feature" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_get_num_feature(booster) |> unwrap!() == 3
  end

  test "booster_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()

    assert EXGBoost.NIF.booster_set_str_feature_info(booster, ~c"feature_name", [
             ~c"name",
             ~c"color",
             ~c"length"
           ]) == :ok
  end

  test "booster_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()

    EXGBoost.NIF.booster_set_str_feature_info(booster, ~c"feature_name", [
      ~c"name",
      ~c"color",
      ~c"length"
    ])

    assert EXGBoost.NIF.booster_get_str_feature_info(booster, ~c"feature_name") |> unwrap!()
  end

  test "booster_feature_score returns feature names, shape, and flattened scores" do
    x =
      Nx.tensor(
        [
          [0.0, 0.0, 0.0],
          [0.0, 1.0, 1.0],
          [0.0, 2.0, 0.0],
          [0.0, 3.0, 1.0],
          [1.0, 0.0, 1.0],
          [1.0, 1.0, 0.0],
          [1.0, 2.0, 1.0],
          [1.0, 3.0, 0.0]
        ],
        type: {:f, 32}
      )

    y =
      Nx.tensor(
        [0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0],
        type: {:f, 32}
      )

    booster =
      EXGBoost.train(
        x,
        y,
        objective: :reg_squarederror,
        tree_method: :hist,
        num_boost_rounds: 5,
        max_depth: 2,
        seed: 0,
        verbose_eval: false
      )

    assert {:ok, {feature_names, shape, scores}} =
             EXGBoost.NIF.booster_feature_score(
               booster.ref,
               Jason.encode!(%{importance_type: "weight"})
             )

    assert is_list(feature_names)
    assert is_tuple(shape)
    assert is_list(scores)

    # This dataset should always produce at least one split.
    assert feature_names != []
    assert scores != []

    # The first shape dimension corresponds to the number of returned
    # feature names.
    assert tuple_size(shape) >= 1
    assert elem(shape, 0) == length(feature_names)

    # Scores are returned flattened, so their count must equal the
    # product of all dimensions in the returned shape.
    expected_score_count =
      shape
      |> Tuple.to_list()
      |> Enum.product()

    assert length(scores) == expected_score_count

    # enif_make_string/3 currently returns feature names as charlists.
    assert Enum.all?(feature_names, fn name ->
             is_list(name) and List.ascii_printable?(name)
           end)

    assert Enum.all?(scores, &is_float/1)
    assert Enum.all?(scores, &(&1 >= 0.0))

    # Labels depend entirely on the first input column, so f0 should
    # have been selected by the model.
    assert "f0" in Enum.map(feature_names, &to_string/1)
  end

  test "save model" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    json_file = Path.join(System.tmp_dir!(), "model.json") |> String.to_charlist()
    ubj_file = Path.join(System.tmp_dir!(), "model.ubj") |> String.to_charlist()
    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_save_model(booster, json_file) |> unwrap!() == :ok
    assert EXGBoost.NIF.booster_save_model(booster, ubj_file) |> unwrap!() == :ok
    assert File.exists?(json_file) and File.regular?(json_file)
    assert File.exists?(ubj_file) and File.regular?(ubj_file)
    assert File.rm(json_file) == :ok
    assert File.rm(ubj_file) == :ok
  end

  test "load model" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    json_file = Path.join(System.tmp_dir!(), "model.json") |> String.to_charlist()
    ubj_file = Path.join(System.tmp_dir!(), "model.ubj") |> String.to_charlist()
    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_save_model(booster, json_file) |> unwrap!() == :ok
    assert EXGBoost.NIF.booster_save_model(booster, ubj_file) |> unwrap!() == :ok
    assert File.exists?(json_file) and File.regular?(json_file)
    assert File.exists?(ubj_file) and File.regular?(ubj_file)
    assert EXGBoost.NIF.booster_load_model(json_file) |> unwrap!() != :error
    assert EXGBoost.NIF.booster_load_model(ubj_file) |> unwrap!() != :error
  end

  test "booster serialize" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_serialize_to_buffer(booster) |> unwrap!() != :error
  end

  test "booster deserialize" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    buffer = EXGBoost.NIF.booster_serialize_to_buffer(booster) |> unwrap!()
    EXGBoost.NIF.booster_deserialize_from_buffer(buffer)
    assert EXGBoost.NIF.booster_deserialize_from_buffer(buffer) |> unwrap!() != :error
  end

  test "save booster config" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_save_json_config(booster) |> unwrap!() != :error
  end

  test "load booster config" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    mat_arr = from_tensor(mat)

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(
        to_tuple(mat_arr),
        config()
      )
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    buf = EXGBoost.NIF.booster_save_json_config(booster) |> unwrap!()
    assert EXGBoost.NIF.booster_load_json_config(booster, buf) |> unwrap!() != :error
  end

  describe "Array Interface safety validations" do
    test "rejects invalid typestr format" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<1, 2, 3, 4, 5, 6, 7, 8>>,
          typestr: "invalid_typestr",
          shape: {2},
          readonly: true
        })

      result =
        EXGBoost.NIF.dmatrix_create_from_dense(
          to_tuple(array_interface),
          config()
        )

      assert {:error, error_msg} = result
      # Error message should mention typestr or element size validation
      error_str = to_string(error_msg)
      assert error_str =~ ~r/(typestr|Typestr|element size)/i
    end

    test "accepts a binary matching the declared shape and type" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary:
            <<1.0::float-32-little, 2.0::float-32-little, 3.0::float-32-little,
              4.0::float-32-little>>,
          typestr: "<f4",
          shape: {1, 4},
          readonly: true
        })

      assert {:ok, _dmatrix_ref} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(array_interface),
                 config()
               )
    end

    test "rejects a binary smaller than the declared shape requires" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<1.0::float-32-little, 2.0::float-32-little>>,
          typestr: "<f4",
          shape: {100, 100},
          readonly: true
        })

      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(array_interface),
                 config()
               )

      assert to_string(error_msg) ==
               "Binary is too small for the specified shape and type"
    end

    test "rejects shape size multiplication overflow" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<0>>,
          typestr: "|u1",
          shape: {18_446_744_073_709_551_615, 2},
          readonly: true
        })

      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(array_interface),
                 config()
               )

      assert to_string(error_msg) =~ "overflow"
    end

    test "rejects negative shape dimensions" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<0.0::float-32-little>>,
          typestr: "<f4",
          shape: {-1},
          readonly: true
        })

      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(array_interface),
                 config()
               )

      assert to_string(error_msg) =~ "non-negative"
    end

    test "rejects malformed readonly value" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<0.0::float-32-little>>,
          typestr: "<f4",
          shape: {1, 1},
          readonly: :yes
        })

      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(array_interface),
                 config()
               )

      assert to_string(error_msg) =~ "boolean"
    end

    test "rejects invalid readonly value" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<1.0::float-32-little, 2.0::float-32-little>>,
          typestr: "<f4",
          shape: {2},
          # Invalid: string instead of boolean atom
          readonly: "not_a_boolean"
        })

      result =
        EXGBoost.NIF.dmatrix_create_from_dense(
          to_tuple(array_interface),
          config()
        )

      assert {:error, error_msg} = result
      error_str = to_string(error_msg)
      assert error_str =~ "boolean" or error_str =~ "readonly"
    end

    test "succeeds with valid parameters" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary:
            <<1.0::float-32-little, 2.0::float-32-little, 3.0::float-32-little,
              4.0::float-32-little>>,
          typestr: "<f4",
          shape: {2, 2},
          readonly: true
        })

      result =
        EXGBoost.NIF.dmatrix_create_from_dense(
          to_tuple(array_interface),
          config()
        )

      assert {:ok, _dmatrix_ref} = result
    end

    test "validates typestr with different endianness markers" do
      # Little-endian with float (4 bytes)
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<1.0::float-32-little, 2.0::float-32-little>>,
          typestr: "<f4",
          shape: {2},
          readonly: true
        })

      # Little-endian should work
      assert {:ok, _} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(array_interface),
                 config()
               )

      # Non-endian (|) is only valid for single-byte types
      assert {:ok, _} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | binary: <<1, 2>>, typestr: "|i1"}),
                 config()
               )

      # Non-endian with multi-byte type should fail
      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | typestr: "|i4"}),
                 config()
               )

      assert to_string(error_msg) =~ "only valid for single-byte types"

      # Invalid endianness marker should fail
      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | typestr: "?f4"}),
                 config()
               )

      assert to_string(error_msg) =~ ~r/(endianness|Typestr)/

      # Big-endian should be rejected (not supported until byte-swapping implemented)
      assert {:error, error_msg} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | typestr: ">f4"}),
                 config()
               )

      assert to_string(error_msg) =~ ~r/(big-endian|not supported)/i
    end

    test "validates shape with overflow protection" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<1.0::float-32-little, 2.0::float-32-little>>,
          typestr: "<f4",
          # Would require 4TB!
          shape: {1_000_000, 1_000_000},
          readonly: true
        })

      # Extremely large shape that would overflow
      # Note: This might not fail if XGBoost itself fails first,
      # but our validation should catch reasonable overflows
      result =
        EXGBoost.NIF.dmatrix_create_from_dense(
          to_tuple(array_interface),
          config()
        )

      assert {:error, _error_msg} = result
    end

    test "strict boolean validation requires atoms" do
      array_interface =
        struct!(EXGBoost.ArrayInterface, %{
          binary: <<1.0::float-32-little, 2.0::float-32-little>>,
          typestr: "<f4",
          shape: {2},
          readonly: true
        })

      # Integer should fail
      assert {:error, _} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | readonly: 1}),
                 config()
               )

      # String should fail
      assert {:error, _} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | readonly: "true"}),
                 config()
               )

      # Only true/false atoms should work
      assert {:ok, _} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | readonly: true}),
                 config()
               )

      assert {:ok, _} =
               EXGBoost.NIF.dmatrix_create_from_dense(
                 to_tuple(%{array_interface | readonly: false}),
                 config()
               )
    end
  end

  # Helper to build config with missing value
  defp config(opts \\ []) do
    Map.merge(%{"missing" => -1.0}, Enum.into(opts, %{}))
    |> Jason.encode!()
  end
end
