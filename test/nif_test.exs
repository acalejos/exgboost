defmodule NifTest do
  use ExUnit.Case
  doctest Exgboost.NIF

  test "exgboost_version" do
    assert Exgboost.NIF.exgboost_version() == {:ok, {2, 0, 0}}
  end

  test "exg_build_info" do
    assert Exgboost.NIF.exg_build_info() ==
             {:ok,
              '{"BUILTIN_PREFETCH_PRESENT":true,"DEBUG":false,"GCC_VERSION":[9,3,0],"MM_PREFETCH_PRESENT":true,"USE_CUDA":false,"USE_FEDERATED":false,"USE_NCCL":false,"USE_OPENMP":true,"USE_RMM":false}'}
  end

  test "exg_set_global_config" do
    assert Exgboost.NIF.exg_set_global_config('{"use_rmm":false,"verbosity":1}') == :ok

    assert Exgboost.NIF.exg_set_global_config('{"use_rmm":false,"verbosity": true}') ==
             {:error, 'Invalid Parameter format for verbosity expect int but value=\'true\''}
  end

  test "exg_get_global_config" do
    assert Exgboost.NIF.exg_get_global_config() == {:ok, '{"use_rmm":false,"verbosity":1}'}
  end

  test "exg_dmatrix_create_from_csr" do
    {:ok, config} =
      Exgboost.NIF.exg_get_global_config() |> Exgboost.Shared.unwrap!() |> Jason.decode()

    Exgboost.NIF.exg_set_global_config(Jason.encode!(Map.put(config, "missing", 0.0)))
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

    assert Exgboost.NIF.exg_dmatrix_create_from_csr(indptr, indices, data, ncols, config) ==
             {:ok, _Reference}
  end

  test "exg_dmatrix_create_from_csr" do
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

    assert Exgboost.NIF.exg_dmatrix_create_from_csrex(
             Nx.to_binary(indptr),
             Nx.to_binary(indices),
             Nx.to_binary(data),
             nindptr,
             nelem,
             ncols
           ) ==
             {:ok, _Reference}
  end
end
