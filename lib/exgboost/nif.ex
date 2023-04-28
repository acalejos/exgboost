defmodule Exgboost.NIF do
  @moduledoc """
  NIF bindings for XGBoost C API. Not to be exposed to users.

  All binding return {:ok, result} or {:error, "error message"}.
  """

  @on_load :on_load

  def on_load do
    IO.puts(:code.priv_dir(:exgboost))
    path = :filename.join([:code.priv_dir(:exgboost), "libexgboost"])
    :erlang.load_nif(path, 0)
  end

  @doc """
  Get the version of the XGBoost library.

  {major, minor, patch}.

  ## Examples

      iex> Exgboost.NIF.xgboost_version()
      {:ok, {2, 0, 0}}
  """
  def xgboost_version, do: :erlang.nif_error(:not_implemented)

  @doc """
  Get compile information of the XGBoost shared library.

  Returns a string encoded JSON object containing build flags and dependency version.

  ## Examples

    iex> Exgboost.NIF.xgboost_build_info()
    {:ok,'{"BUILTIN_PREFETCH_PRESENT":true,"DEBUG":false,"GCC_VERSION":[9,3,0],"MM_PREFETCH_PRESENT":true,"USE_CUDA":false,"USE_FEDERATED":false,"USE_NCCL":false,"USE_OPENMP":true,"USE_RMM":false}'}
  """
  def xgboost_build_info, do: :erlang.nif_error(:not_implemented)

  @doc """
  Set global config for XGBoost using a string encoded flat json.

  Returns `:ok` if the config is set successfully.

  ## Examples

      iex> Exgboost.NIF.set_global_config('{"use_rmm":false,"verbosity":1}')
      :ok
      iex> Exgboost.NIF.set_global_config('{"use_rmm":false,"verbosity": true}')
      {:error, 'Invalid Parameter format for verbosity expect int but value=\'true\''}
  """
  def set_global_config(_config), do: :erlang.nif_error(:not_implemented)

  @doc """
  Get global config for XGBoost as a string encoded flat json.

  Returns a string encoded flat json.

  ## Examples

      iex> Exgboost.NIF.get_global_config()
      {:ok, '{"use_rmm":false,"verbosity":1}'}
  """
  def get_global_config, do: :erlang.nif_error(:not_implemented)

  @doc """
  Create a DMatrix from a filename

  This function will break on an improper file type and parse and should thus be avoided.
  This is here for completeness sake but should not be used.

  Refer to https://github.com/dmlc/xgboost/issues/9059

  """
  def dmatrix_create_from_file(_file_path, _silent, _file_format),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Create a DMatrix from an Nx Tensor of type {:f, 32}.

  Returns a reference to the DMatrix.

  ## Examples

      iex> Exgboost.NIF.dmatrix_create_from_mat(Nx.to_binary(Nx.tensor([1.0, 2.0, 3.0, 4.0])),1,4, -1.0)
      {:ok, #Reference<>}
      iex> Exgboost.NIF.dmatrix_create_from_mat(Nx.to_binary(Nx.tensor([1, 2, 3, 4])),1,2, -1.0)
      {:error, 'Data size does not match nrow and ncol'}
  """
  def dmatrix_create_from_mat(_data, _nrow, _ncol, _missing),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Create a DMatrix from a CSR matrix

  Returns a reference to the DMatrix.

  ## Examples

      iex> Exgboost.NIF.dmatrix_create_from_csr([0, 2, 3], [0, 2, 2, 0], [1, 2, 3, 4], 2, 2, -1.0)
      {:ok, #Reference<>}

      iex> Exgboost.NIF.dmatrix_create_from_csr([0, 2, 3], [0, 2, 2, 0], [1, 2, 3, 4], 2, 2, -1.0)
      {:error #Reference<>}
  """
  def dmatrix_create_from_csr(_indptr, _indices, _data, _ncol, _config),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  WARNING: XGDMatrixCreateFromCSREx` is deprecated since 2.0.0, use `XGDMatrixCreateFromCSR` instead
  """
  def dmatrix_create_from_csrex(_indptr, _indices, _data, _nindptr, _nelem, _ncol),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Create a DMatrix from a JSON-Encoded Array-Interface
  https://numpy.org/doc/stable/reference/arrays.interface.html

  """
  def dmatrix_create_from_dense(_data, _array_interface, _config),
    do: :erlang.nif_error(:not_implemented)

  def dmatrix_get_str_feature_info(_dmatrix_resource, _field),
    do: :erlang.nif_error(:not_implemented)

  def dmatrix_set_str_feature_info(_dmatrix_resource, _field, _features),
    do: :erlang.nif_error(:not_implemented)
end
