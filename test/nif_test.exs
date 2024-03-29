defmodule NifTest do
  use ExUnit.Case, async: true
  import EXGBoost.Internal
  import EXGBoost.ArrayInterface, only: [from_tensor: 1]

  test "exgboost_version" do
    assert EXGBoost.NIF.xgboost_version() |> unwrap!() != :error
  end

  test "build_info" do
    assert EXGBoost.NIF.xgboost_build_info() |> unwrap!() != :error
  end

  test "set_global_config" do
    assert EXGBoost.NIF.set_global_config('{"use_rmm":false,"verbosity":1}') == :ok

    assert EXGBoost.NIF.set_global_config('{"use_rmm":false,"verbosity": true}') ==
             {:error, 'Invalid Parameter format for verbosity expect int but value=\'true\''}
  end

  test "get_global_config" do
    assert EXGBoost.NIF.get_global_config() |> unwrap!() != :error
  end

  test "dmatrix_create_from_uri" do
    config = Jason.encode!(%{uri: "test/data/train.txt?format=libsvm"})
    assert EXGBoost.NIF.dmatrix_create_from_uri(config) |> unwrap!() != :error
  end

  test "dmatrix_create_from_sparse" do
    config = Jason.encode!(%{"missing" => 0.0})
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

    assert EXGBoost.NIF.dmatrix_create_from_sparse(
             from_tensor(indptr) |> Jason.encode!(),
             from_tensor(indices) |> Jason.encode!(),
             from_tensor(data) |> Jason.encode!(),
             ncols,
             config,
             "csr"
           )
           |> unwrap!() !=
             :error

    assert EXGBoost.NIF.dmatrix_create_from_sparse(
             from_tensor(indptr) |> Jason.encode!(),
             from_tensor(indices) |> Jason.encode!(),
             from_tensor(data) |> Jason.encode!(),
             ncols,
             config,
             "csc"
           )
           |> unwrap!() !=
             :error

    {status, _} =
      EXGBoost.NIF.dmatrix_create_from_sparse(
        from_tensor(indptr) |> Jason.encode!(),
        from_tensor(indices) |> Jason.encode!(),
        from_tensor(data) |> Jason.encode!(),
        ncols,
        config,
        "csa"
      )

    assert status == :error
  end

  test "test_dmatrix_create_from_dense" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    assert EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
           |> unwrap!() !=
             :error
  end

  test "test_dmatrix_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', [
             'name',
             'color',
             'length'
           ]) == :ok
  end

  test "test_dmatrix_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    EXGBoost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', ['name', 'color', 'length'])

    assert EXGBoost.NIF.dmatrix_get_str_feature_info(dmat, 'feature_name') |> unwrap!()
  end

  test "dmatrix_num_row" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_row(dmat) |> unwrap! == 2
  end

  test "dmatrix_num_col" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_col(dmat) |> unwrap! == 3
  end

  test "dmatrix_num_non_missing" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_num_non_missing(dmat) |> unwrap! == 6
  end

  test "dmatrix_set_info_from_interface" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()
    labels = Nx.tensor([1.0, 0.0])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    label_interface = from_tensor(labels) |> Jason.encode!()

    assert EXGBoost.NIF.dmatrix_set_info_from_interface(
             dmat,
             'label',
             label_interface
           ) ==
             :ok

    assert EXGBoost.NIF.dmatrix_set_info_from_interface(
             dmat,
             'unsupported',
             label_interface
           ) != :ok
  end

  test "dmatrix_save_binary" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()
    labels = Nx.tensor([1.0, 0.0])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    interface = from_tensor(labels) |> Jason.encode!()

    EXGBoost.NIF.dmatrix_set_info_from_interface(dmat, 'label', interface)

    path = Path.join(System.tmp_dir!(), "test.buffer") |> String.to_charlist()
    assert EXGBoost.NIF.dmatrix_save_binary(dmat, path, 1) == :ok
  end

  test "dmatrix_get_float_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()
    weights = Nx.tensor([1.0, 0.0])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    interface = from_tensor(weights) |> Jason.encode!()
    EXGBoost.NIF.dmatrix_set_info_from_interface(dmat, 'feature_weights', interface)

    assert EXGBoost.NIF.dmatrix_get_float_info(dmat, 'feature_weights') |> unwrap!() ==
             Nx.to_list(weights)
  end

  test "dmatrix_get_data_as_csr" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert EXGBoost.NIF.dmatrix_get_data_as_csr(dmat, Jason.encode!(%{})) |> unwrap!() != :error
  end

  test "dmatrix_slice" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
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
    array_interface = from_tensor(mat) |> Jason.encode!()
    array_interface2 = from_tensor(mat2) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    dmat2 =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface2, config)
      |> unwrap!()

    assert EXGBoost.NIF.booster_create([dmat]) |> unwrap!() != :error
    assert EXGBoost.NIF.booster_create([]) |> unwrap!() != :error
    assert EXGBoost.NIF.booster_create([dmat, dmat2]) |> unwrap!() != :error
  end

  test "booster_get_num_feature" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_get_num_feature(booster) |> unwrap!() == 3
  end

  test "test_booster_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()

    assert EXGBoost.NIF.booster_set_str_feature_info(booster, 'feature_name', [
             'name',
             'color',
             'length'
           ]) == :ok
  end

  test "test_booster_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()

    EXGBoost.NIF.booster_set_str_feature_info(booster, 'feature_name', ['name', 'color', 'length'])

    assert EXGBoost.NIF.booster_get_str_feature_info(booster, 'feature_name') |> unwrap!()
  end

  test "test_boster_feature_score" do
    # TODO: Make more robust test. This will just return an empty list
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    config = Jason.encode!(%{"importance_type" => "weight"})
    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()

    assert EXGBoost.NIF.booster_feature_score(booster, config) |> unwrap!() != :error
  end

  test "save model" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
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
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
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
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_serialize_to_buffer(booster) |> unwrap!() != :error
  end

  test "booster deserialize" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    buffer = EXGBoost.NIF.booster_serialize_to_buffer(booster) |> unwrap!()
    EXGBoost.NIF.booster_deserialize_from_buffer(buffer)
    assert EXGBoost.NIF.booster_deserialize_from_buffer(buffer) |> unwrap!() != :error
  end

  test "save booster config" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    assert EXGBoost.NIF.booster_save_json_config(booster) |> unwrap!() != :error
  end

  test "load booster config" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = from_tensor(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      EXGBoost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = EXGBoost.NIF.booster_create([dmat]) |> unwrap!()
    buf = EXGBoost.NIF.booster_save_json_config(booster) |> unwrap!()
    assert EXGBoost.NIF.booster_load_json_config(booster, buf) |> unwrap!() != :error
  end
end
