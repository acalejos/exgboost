defmodule Exgboost.NIF do
  @moduledoc false

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
  @type dmatrix_reference :: reference()
  @type booster_reference :: reference()
  @type exgboost_return_type(return_type) :: {:ok, return_type} | {:error, String.t()}

  def on_load do
    path = :filename.join([:code.priv_dir(:exgboost), "libexgboost"])
    :erlang.load_nif(path, 0)
  end

  @spec get_int_size :: integer()
  def get_int_size, do: :erlang.nif_error(:not_implemented)

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

  @spec set_global_config(String.t()) :: :ok | {:error, String.t()}
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

  @spec dmatrix_create_from_file(String.t(), Integer) ::
          exgboost_return_type(reference)
  @doc """
  Create a DMatrix from a filename

  **WARNING** This function will break on an improper file type and parse and thus the user
  should take EXTREME caution when using this, and avoid calling directly. Instead
  use the `Exgboost.dmatrix` function.

  This is set to be fixed with the 2.0.0 release of XGBoost.

  Refer to https://github.com/dmlc/xgboost/issues/9059

  """
  def dmatrix_create_from_file(_file_uri, _silent),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_create_from_mat(binary, integer(), integer(), float()) ::
          exgboost_return_type(dmatrix_reference())
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

  @spec dmatrix_create_from_sparse(
          array_interface(),
          array_interface(),
          array_interface(),
          integer(),
          String.t(),
          String.t()
        ) :: exgboost_return_type(dmatrix_reference())
  @doc """
  Create a DMatrix from a Sparse matrix (CSR / CSC)

  Returns a reference to the DMatrix.

  ## Examples

      iex> Exgboost.NIF.dmatrix_create_from_csr([0, 2, 3], [0, 2, 2, 0], [1, 2, 3, 4], 2, 2, -1.0)
      {:ok, #Reference<>}

      iex> Exgboost.NIF.dmatrix_create_from_csr([0, 2, 3], [0, 2, 2, 0], [1, 2, 3, 4], 2, 2, -1.0)
      {:error #Reference<>}
  """
  def dmatrix_create_from_sparse(
        _indptr_interface,
        _indices_interface,
        _data_interface,
        _n,
        _config,
        _format
      ),
      do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_create_from_dense(array_interface(), String.t()) ::
          exgboost_return_type(dmatrix_reference())
  @doc """
  Create a DMatrix from a JSON-Encoded Array-Interface
  https://numpy.org/doc/stable/reference/arrays.interface.html

  """
  def dmatrix_create_from_dense(_array_interface, _config),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_get_str_feature_info(dmatrix_reference(), String.t()) ::
          exgboost_return_type([String.t()])
  def dmatrix_get_str_feature_info(_dmatrix_resource, _field),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_set_str_feature_info(dmatrix_reference(), String.t(), [String.t()]) ::
          :ok | {:error, String.t()}
  def dmatrix_set_str_feature_info(_dmatrix_resource, _field, _features),
    do: :erlang.nif_error(:not_implemented)

  @deprecated "Use dmatrix_set_info_from_interface/4 instead"
  @spec dmatrix_set_dense_info(
          dmatrix_reference(),
          String.t(),
          binary,
          pos_integer(),
          xgboost_data_type()
        ) :: :ok | {:error, String.t()}
  def dmatrix_set_dense_info(_handle, _field, _data, _size, _type),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_num_row(dmatrix_reference()) :: exgboost_return_type(pos_integer())
  def dmatrix_num_row(_handle), do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_num_col(dmatrix_reference()) :: exgboost_return_type(pos_integer())
  def dmatrix_num_col(_handle), do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_num_non_missing(dmatrix_reference()) :: exgboost_return_type(pos_integer())
  def dmatrix_num_non_missing(_handle), do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_set_info_from_interface(
          dmatrix_reference(),
          String.t(),
          array_interface()
        ) :: :ok | {:error, String.t()}
  @doc """
  Set the info from an array interface
  Valid fields are:
  Set meta info from dense matrix. Valid field names are:
  * label
  * weight
  * base_margin
  * group
  * label_lower_bound
  * label_upper_bound
  * feature_weights
  """
  def dmatrix_set_info_from_interface(_handle, _field, _data_interface),
    do: :erlang.nif_error(:not_implemented)

  @spec dmatrix_save_binary(dmatrix_reference(), String.t(), integer()) ::
          exgboost_return_type(:ok)
  def dmatrix_save_binary(_handle, _fname, _silent),
    do: :erlang.nif_error(:not_implemented)

  @spec get_binary_address(dmatrix_reference()) :: exgboost_return_type(integer)
  def get_binary_address(_handle),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Gets a field from the DMatrix. Valid fields are:
  * label
  * weight
  * base_margin
  * label_lower_bound
  * label_upper_bound
  * feature_weights
  """
  @spec dmatrix_get_float_info(dmatrix_reference(), String.t()) :: exgboost_return_type([float])
  def dmatrix_get_float_info(_handle, _field),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Gets a field from the DMatrix. Valid fields are:
  * group_ptr
  """
  @spec dmatrix_get_uint_info(dmatrix_reference(), String.t()) ::
          exgboost_return_type([pos_integer()])
  def dmatrix_get_uint_info(_handle, _field),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Get data field from DMatrix.

  * config: At the moment it should be an empty document, preserved for future use.

  Returns 3-tuple of {indptr, indices, data}
  """
  @spec dmatrix_get_data_as_csr(dmatrix_reference(), String.t()) ::
          exgboost_return_type({[pos_integer()], [pos_integer()], [float]})
  def dmatrix_get_data_as_csr(_handle, _config),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Create a DMatrix from a slice of rows from an existing DMAtrix

  Expects a binary of `int`s so you should query for the size of the C int using
  NIF.get_int_size/0 and then use that to pack the binary, or use Nx.tensor(_intput, type: type)
  to get a binary of the correct size.
  """
  @spec dmatrix_slice(dmatrix_reference(), binary(), 0 | 1) :: dmatrix_reference()
  def dmatrix_slice(_handle, _index_set, _allow_groups), do: :erlang.nif_error(:not_implemented)

  @spec booster_create([dmatrix_reference()]) :: exgboost_return_type(booster_reference())
  def booster_create(_handles), do: :erlang.nif_error(:not_implemented)

  @spec booster_slice(booster_reference(), integer(), integer(), integer()) ::
          exgboost_return_type(booster_reference())
  def booster_slice(_handle, _begin_layer, _end_layer, _step),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_boosted_rounds(booster_reference()) :: exgboost_return_type(integer())
  def booster_boosted_rounds(_handle), do: :erlang.nif_error(:not_implemented)

  @spec booster_set_param(booster_reference(), String.t(), String.t()) ::
          :ok | {:error, String.t()}
  def booster_set_param(_handle, _param, _value), do: :erlang.nif_error(:not_implemented)

  @spec booster_get_num_feature(booster_reference()) :: exgboost_return_type(pos_integer())
  def booster_get_num_feature(_handle), do: :erlang.nif_error(:not_implemented)

  @spec booster_update_one_iter(booster_reference(), dmatrix_reference(), integer()) ::
          :ok | {:error, String.t()}
  def booster_update_one_iter(_booster_handle, _dmatrix_handle, _iteration),
    do: :erlang.nif_error(:not_implemented)

  @doc """
  Update the model, by directly specify gradient and second order gradient, this can be used to replace UpdateOneIter, to support customized loss function

  Grad and hess must be binaries of Nx.Tensor float32
  """
  @spec booster_boost_one_iter(booster_reference(), dmatrix_reference(), binary(), binary()) ::
          :ok | {:error, String.t()}
  def booster_boost_one_iter(_booster_handle, _dmatrix_handle, _grad, _hess),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_eval_one_iter(booster_reference(), pos_integer(), [dmatrix_reference()], [
          String.t()
        ]) :: exgboost_return_type(String.t())
  def booster_eval_one_iter(_booster_handle, _iteration, _dmatrix_handles, _eval_names),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_get_attr_names(booster_reference()) :: exgboost_return_type([String.t()])
  def booster_get_attr_names(_booster_handle), do: :erlang.nif_error(:not_implemented)

  @spec booster_get_attr(booster_reference(), String.t()) :: exgboost_return_type(String.t())
  def booster_get_attr(_booster_handle, _key), do: :erlang.nif_error(:not_implemented)

  @spec booster_set_attr(booster_reference(), String.t(), String.t()) ::
          :ok | {:error, String.t()}
  def booster_set_attr(_booster_handle, _key, _value), do: :erlang.nif_error(:not_implemented)

  @spec booster_get_str_feature_info(booster_reference(), String.t()) ::
          exgboost_return_type([String.t()])
  def booster_get_str_feature_info(_booster_resource, _field),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_set_str_feature_info(booster_reference(), String.t(), [String.t()]) ::
          :ok | {:error, String.t()}
  def booster_set_str_feature_info(_booster_resource, _field, _features),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_feature_score(booster_reference(), String.t()) ::
          exgboost_return_type(tuple())
  def booster_feature_score(_booster_resource, _config),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_predict_from_dmatrix(booster_reference(), dmatrix_reference(), String.t()) ::
          tuple()
  def booster_predict_from_dmatrix(_boster, _dmatrix, _config),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_predict_from_dense(booster_reference(), String.t(), String.t(), reference() | nil) ::
          tuple()
  def booster_predict_from_dense(_boster, _values, _config, _proxy),
    do: :erlang.nif_error(:not_implemented)

  @spec booster_predict_from_csr(
          booster_reference(),
          String.t(),
          String.t(),
          String.t(),
          integer(),
          String.t(),
          reference() | nil
        ) ::
          tuple()
  def booster_predict_from_csr(_boster, _indptr, _indices, _values, _ncols, _config, _proxy),
    do: :erlang.nif_error(:not_implemented)

  @spec proxy_dmatrix_create() :: dmatrix_reference()
  def proxy_dmatrix_create, do: :erlang.nif_error(:not_implemented)

  @spec booster_load_model(String.t()) ::
          exgboost_return_type(booster_reference())
  def booster_load_model( _path), do: :erlang.nif_error(:not_implemented)

  @spec booster_save_model(booster_reference(), String.t()) ::
          :ok | {:error, String.t()}
  def booster_save_model(_handle, _path), do: :erlang.nif_error(:not_implemented)
end
