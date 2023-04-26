defmodule NifTest do
  use ExUnit.Case
  alias Exgboost.Shared
  doctest Exgboost.NIF

  test "exgboost_version" do
    assert Exgboost.NIF.xgboost_version() == {:ok, {2, 0, 0}}
  end

  test "build_info" do
    assert Exgboost.NIF.xgboost_build_info() ==
             {:ok,
              '{"BUILTIN_PREFETCH_PRESENT":true,"DEBUG":false,"GCC_VERSION":[9,3,0],"MM_PREFETCH_PRESENT":true,"USE_CUDA":false,"USE_FEDERATED":false,"USE_NCCL":false,"USE_OPENMP":true,"USE_RMM":false}'}
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
    indptr = Jason.encode!([0, 22])
    ncols = 127

    indices =
      Jason.encode!([
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
      Jason.encode!([
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

    assert Exgboost.NIF.dmatrix_create_from_csr(indptr, indices, data, ncols, config) ==
             {:ok, _Reference}
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
           ) ==
             {:ok, _Reference}
  end

  test "test_dmatrix_create_from_dense" do
    mat = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    array_interface = Shared.to_array_interface(mat)

    config = config = Jason.encode!(%{"missing" => -1.0})

    assert Exgboost.NIF.dmatrix_create_from_dense(Nx.to_binary(mat), array_interface, config) ==
             {:ok, _Reference}
  end
end
