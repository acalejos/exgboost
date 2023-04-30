defmodule NifTest do
  use ExUnit.Case
  alias Exgboost.Shared
  # doctest Exgboost.NIF

  test "exgboost_version" do
    assert Exgboost.NIF.xgboost_version() |> Shared.unwrap!() != :error
  end

  test "build_info" do
    assert Exgboost.NIF.xgboost_build_info() |> Shared.unwrap!() != :error
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
             Shared.to_array_interface(indptr),
             Nx.to_binary(indices),
             Shared.to_array_interface(indices),
             Nx.to_binary(data),
             Shared.to_array_interface(data),
             ncols,
             config
           )
           |> Shared.unwrap!() !=
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
           |> Shared.unwrap!() !=
             :error
  end

  test "test_dmatrix_create_from_dense" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = Shared.to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    assert Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
           |> Shared.unwrap!() !=
             :error
  end

  test "test_dmatrix_set_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = Shared.to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
      |> Shared.unwrap!()

    assert Exgboost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', [
             'name',
             'color',
             'length'
           ]) == :ok
  end

  test "test_dmatrix_get_str_feature_info" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = Shared.to_array_interface(mat)

    config = Jason.encode!(%{"missing" => -1.0})

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config)
      |> Shared.unwrap!()

    Exgboost.NIF.dmatrix_set_str_feature_info(dmat, 'feature_name', ['name', 'color', 'length'])

    assert Exgboost.NIF.dmatrix_get_str_feature_info(dmat, 'feature_name') |> Shared.unwrap!()
  end
end
