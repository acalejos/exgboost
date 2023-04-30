defmodule Exgboost.NIF do
  @moduledoc """
  NIF bindings for XGBoost C API. Not to be exposed to users.

  All binding return {:ok, result} or {:error, "error message"}.
  """

  @on_load :on_load

  @typedoc """
  Indicator of data type. This is defined in xgboost::DataType enum class.
  float = 1
  double = 2
  uint32_t = 3
  uint64_t = 4
  """
  @type xgboost_data_type :: 1..4
  @typedoc """
  JSON-Encoded Array Interface as defined in the NumPy documentation.
  https://numpy.org/doc/stable/reference/arrays.interface.html
  """
  @type array_interface :: String.t()
  @type exgboost_return_type(return_type) :: {:ok, return_type} | {:error, String.t()}

  def on_load do
    IO.puts(:code.priv_dir(:exgboost))
    path = :filename.join([:code.priv_dir(:exgboost), "libexgboost"])
    :erlang.load_nif(path, 0)
  end

  @spec xgboost_version :: exgboost_return_type(tuple)
  @doc """
  Get the version of the XGBoost library.

  {major, minor, patch}.

  ## Examples

      iex> Exgboost.NIF.xgboost_version()
      {:ok, {2, 0, 0}}
  """
  def xgboost_version, do: :erlang.nif_error(:not_implemented)

  @spec xgboost_build_info :: exgboost_return_type(String.t())
  @doc """
  Get compile information of the XGBoost shared library.

  Returns a string encoded JSON object containing build flags and dependency version.

  ## Examples

    iex> Exgboost.NIF.xgboost_build_info()
    {:ok,'{"BUILTIN_PREFETCH_PRESENT":true,"DEBUG":false,"GCC_VERSION":[9,3,0],"MM_PREFETCH_PRESENT":true,"USE_CUDA":false,"USE_FEDERATED":false,"USE_NCCL":false,"USE_OPENMP":true,"USE_RMM":false}'}
  """
  def xgboost_build_info, do: :erlang.nif_error(:not_implemented)

  @spec set_global_config(String.t()) :: exgboost_return_type(:ok)
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

  @spec get_global_config :: exgboost_return_type(String.t())
  @doc """
  Get global config for XGBoost as a string encoded flat json.

  Returns a string encoded flat json.

  ## Examples

      iex> Exgboost.NIF.get_global_config()
      {:ok, '{"use_rmm":false,"verbosity":1}'}
  """
  def get_global_config, do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_create_from_file(String.t(), Integer, String.t()) ::
          exgboost_return_type(reference)
  @doc """
  Create a DMatrix from a filename

  This function will break on an improper file type and parse and should thus be avoided.
  This is here for completeness sake but should not be used.

  Refer to https://github.com/dmlc/xgboost/issues/9059

  """
  def dmatrix_create_from_file(_file_path, _silent, _file_format),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_create_from_mat(binary, integer(), integer(), float()) ::
          exgboost_return_type(reference)
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

  @spec dmatrix_create_from_csr(
          binary,
          array_interface(),
          binary,
          array_interface(),
          binary,
          array_interface(),
          integer(),
          String.t()
        ) :: exgboost_return_type(reference)
  @doc """
  Create a DMatrix from a CSR matrix

  Returns a reference to the DMatrix.

  ## Examples

      iex> Exgboost.NIF.dmatrix_create_from_csr([0, 2, 3], [0, 2, 2, 0], [1, 2, 3, 4], 2, 2, -1.0)
      {:ok, #Reference<>}

      iex> Exgboost.NIF.dmatrix_create_from_csr([0, 2, 3], [0, 2, 2, 0], [1, 2, 3, 4], 2, 2, -1.0)
      {:error #Reference<>}
  """
  def dmatrix_create_from_csr(
        _indptr,
        _indptr_interface,
        _indices,
        _indices_interface,
        _data,
        _data_interface,
        _ncol,
        _config
      ),
      do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_create_from_csrex(binary, binary, binary, Integer, Integer, Integer) ::
          exgboost_return_type(reference)
  @doc """
  WARNING: XGDMatrixCreateFromCSREx` is deprecated since 2.0.0, use `XGDMatrixCreateFromCSR` instead
  """
  def dmatrix_create_from_csrex(_indptr, _indices, _data, _nindptr, _nelem, _ncol),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_create_from_dense(binary, array_interface(), String.t()) ::
          exgboost_return_type(reference)
  @doc """
  Create a DMatrix from a JSON-Encoded Array-Interface
  https://numpy.org/doc/stable/reference/arrays.interface.html

  """
  def dmatrix_create_from_dense(_data, _array_interface, _config),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_get_str_feature_info(reference(), String.t()) ::
          exgboost_return_type([String.t()])
  def dmatrix_get_str_feature_info(_dmatrix_resource, _field),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_set_str_feature_info(reference(), String.t(), [String.t()]) ::
          exgboost_return_type(:ok)
  def dmatrix_set_str_feature_info(_dmatrix_resource, _field, _features),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_set_dense_info(
          reference(),
          String.t(),
          binary,
          pos_integer(),
          xgboost_data_type()
        ) :: exgboost_return_type(:ok)
  def dmatrix_set_dense_info(_handle, _field, _data, _size, _type),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_num_row(reference()) :: exgboost_return_type(pos_integer())
  def dmatrix_num_row(_handle), do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_num_col(reference()) :: exgboost_return_type(pos_integer())
  def dmatrix_num_col(_handle), do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_num_non_missing(reference()) :: exgboost_return_type(pos_integer())
  def dmatrix_num_non_missing(_handle), do: :erlang.nif_error(:not_implemented)
end
