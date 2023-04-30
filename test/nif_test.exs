defmodule NifTest do
  use ExUnit.Case
  import Exgboost.Shared
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

  test "dmatrix_create_from_csr" do
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

    assert Exgboost.NIF.dmatrix_create_from_csr(
             Nx.to_binary(indptr),
             to_array_interface(indptr),
             Nx.to_binary(indices),
             to_array_interface(indices),
             Nx.to_binary(data),
             to_array_interface(data),
             ncols,
             config
           )
           |> unwrap!() !=
             :error
  end

  test "dmatrix_create_from_csrex" do
    indptr = Nx.tensor([0, 22], type: {:u, 64})
    {nindptr} = indptr.shape
    ncols = 127

    indices =
      Nx.tensor(
        [
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
        ],
        type: {:u, 64}
      )

    data =
      Nx.tensor(
        [
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
        ],
        type: {:f, 32}
      )

    {nelem} = data.shape

    assert Exgboost.NIF.dmatrix_create_from_csrex(
             Nx.to_binary(indptr),
             Nx.to_binary(indices),
             Nx.to_binary(data),
             nindptr,
             nelem,
             ncols
           )
           |> unwrap!() !=
             :error
  end

  test "test_dmatrix_create_from_dense" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    assert Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
           |> unwrap!() !=
             :error
  end

  test "test_dmatrix_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', [
             'name',
             'color',
             'length'
           ]) == :ok
  end

  test "test_dmatrix_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
      |> unwrap!()

    Exgboost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', ['name', 'color', 'length'])

    assert Exgboost.NIF.dmatrix_get_str_feature_info(dmat, 'feature_name') |> unwrap!()
  end

  test "dmatrix_set_dense_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = to_array_interface(mat)
    labels = Nx.tensor([1.0, 0.0])
    {size} = labels.shape

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
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
    array_interface = to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_num_row(dmat) |> unwrap! == 2
  end

  test "dmatrix_num_col" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
      |> unwrap!()

    assert Exgboost.NIF.dmatrix_num_col(dmat) |> unwrap! == 3
  end
end
