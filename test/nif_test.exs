defmodule NifTest do
  use ExUnit.Case
  import Exgboost.Internal
  # doctest Exgboost.NIF

  test "exgboost_version" do
    assert Exgboost.NIF.xgboost_version() |> unwrap!() != :error
  end

  test "build_info" do
    assert Exgboost.NIF.xgboost_build_info() |> unwrap!() != :error
  end

  test "set_global_config" do
    assert Exgboost.NIF.set_global_config('{"use_rmm":false,"verbosity":1}') == :ok

    assert Exgboost.NIF.set_global_config('{"use_rmm":false,"verbosity": true}') ==
             {:error, 'Invalid Parameter format for verbosity expect int but value=\'true\''}
  end

  test "get_global_config" do
    assert Exgboost.NIF.get_global_config() == {:ok, '{"use_rmm":false,"verbosity":1}'}
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

    assert Exgboost.NIF.dmatrix_create_from_sparse(
             array_interface(indptr) |> Jason.encode!(),
             array_interface(indices) |> Jason.encode!(),
             array_interface(data) |> Jason.encode!(),
             ncols,
             config,
             "csr"
           )
           |> unwrap!() !=
             :error

    assert Exgboost.NIF.dmatrix_create_from_sparse(
             array_interface(indptr) |> Jason.encode!(),
             array_interface(indices) |> Jason.encode!(),
             array_interface(data) |> Jason.encode!(),
             ncols,
             config,
             "csc"
           )
           |> unwrap!() !=
             :error

    {status, _} =
      Exgboost.NIF.dmatrix_create_from_sparse(
        array_interface(indptr) |> Jason.encode!(),
        array_interface(indices) |> Jason.encode!(),
        array_interface(data) |> Jason.encode!(),
        ncols,
        config,
        "csa"
      )

    assert status == :error
  end

  test "test_dmatrix_create_from_dense" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    assert Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
           |> unwrap!() !=
             :error
  end

  test "test_dmatrix_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', [
             'name',
             'color',
             'length'
           ]) == :ok
  end

  test "test_dmatrix_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    Exgboost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', ['name', 'color', 'length'])

    assert Exgboost.NIF.dmatrix_get_str_feature_info(dmat, 'feature_name') |> unwrap!()
  end

  test "dmatrix_set_dense_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()
    labels = Nx.tensor([1.0, 0.0])
    {size} = labels.shape

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    type = get_xgboost_data_type(labels) |> unwrap!()

    assert Exgboost.NIF.dmatrix_set_dense_info(dmat, 'weight', Nx.to_binary(labels), size, type) ==
             :ok

    assert Exgboost.NIF.dmatrix_set_dense_info(
             dmat,
             'unsupported',
             Nx.to_binary(labels),
             size,
             type
           ) != :ok
  end

  test "dmatrix_num_row" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_num_row(dmat) |> unwrap! == 2
  end

  test "dmatrix_num_col" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_num_col(dmat) |> unwrap! == 3
  end

  test "dmatrix_num_non_missing" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_num_non_missing(dmat) |> unwrap! == 6
  end

  test "dmatrix_set_info_from_interface" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()
    labels = Nx.tensor([1.0, 0.0])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    label_interface = array_interface(labels) |> Jason.encode!()

    assert Exgboost.NIF.dmatrix_set_info_from_interface(
             dmat,
             'label',
             label_interface
           ) ==
             :ok

    assert Exgboost.NIF.dmatrix_set_info_from_interface(
             dmat,
             'unsupported',
             label_interface
           ) != :ok
  end

  test "dmatrix_save_binary" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()
    labels = Nx.tensor([1.0, 0.0])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    interface = array_interface(labels) |> Jason.encode!()

    Exgboost.NIF.dmatrix_set_info_from_interface(dmat, 'label', interface)

    assert Exgboost.NIF.dmatrix_save_binary(dmat, 'test.buffer', 1) == :ok
  end

  test "dmatrix_get_float_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()
    weights = Nx.tensor([1.0, 0.0])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    interface = array_interface(weights) |> Jason.encode!()
    Exgboost.NIF.dmatrix_set_info_from_interface(dmat, 'feature_weights', interface)

    assert Exgboost.NIF.dmatrix_get_float_info(dmat, 'feature_weights') |> unwrap!() ==
             Nx.to_list(weights)
  end

  test "dmatrix_get_uint_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()
    groups = Nx.tensor([1])

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    interface = array_interface(groups) |> Jason.encode!()
    Exgboost.NIF.dmatrix_set_info_from_interface(dmat, 'group_ptr', interface)
    assert Exgboost.NIF.dmatrix_get_uint_info(dmat, 'group_ptr') |> unwrap!() == groups
  end

  test "dmatrix_get_data_as_csr" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_get_data_as_csr(dmat, Jason.encode!(%{})) |> unwrap!() != :error
  end

  test "booster_create" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.booster_create([dmat]) |> unwrap!() != :error
    assert Exgboost.NIF.booster_create([]) |> unwrap!() != :error
  end

  test "test_booster_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = Exgboost.NIF.booster_create([dmat]) |> unwrap!()

    assert Exgboost.NIF.booster_set_str_feature_info(booster, 'feature_name', [
             'name',
             'color',
             'length'
           ]) == :ok
  end

  test "test_booster_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = array_interface(mat) |> Jason.encode!()

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(array_interface, config)
      |> unwrap!()

    booster = Exgboost.NIF.booster_create([dmat]) |> unwrap!()

    Exgboost.NIF.booster_set_str_feature_info(booster, 'feature_name', ['name', 'color', 'length'])

    assert Exgboost.NIF.booster_get_str_feature_info(booster, 'feature_name') |> unwrap!()
  end
end
