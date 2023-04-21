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

      iex> Exgboost.NIF.exgboost_version()
      {:ok, {2, 0, 0}}
  """
  def exgboost_version, do: :erlang.nif_error(:not_implemented)

  @doc """
  Get compile information of the XGBoost shared library.

  Returns a string encoded JSON object containing build flags and dependency version.

  ## Examples

    iex> Exgboost.NIF.exg_build_info()
    {:ok,'{"BUILTIN_PREFETCH_PRESENT":true,"DEBUG":false,"GCC_VERSION":[9,3,0],"MM_PREFETCH_PRESENT":true,"USE_CUDA":false,"USE_FEDERATED":false,"USE_NCCL":false,"USE_OPENMP":true,"USE_RMM":false}'}
  """
  def exg_build_info, do: :erlang.nif_error(:not_implemented)

  @doc """
  Set global config for XGBoost using a string encoded flat json.

  Returns `:ok` if the config is set successfully.

  ## Examples

      iex> Exgboost.NIF.exg_set_global_config('{"use_rmm":false,"verbosity":1}')
      :ok
      iex> Exgboost.NIF.exg_set_global_config('{"use_rmm":false,"verbosity": true}')
      {:error, 'Invalid Parameter format for verbosity expect int but value=\'true\''}
  """
  def exg_set_global_config(_config), do: :erlang.nif_error(:not_implemented)

  @doc """
  Get global config for XGBoost as a string encoded flat json.

  Returns a string encoded flat json.

  ## Examples

      iex> Exgboost.NIF.exg_get_global_config()
      {:ok, '{"use_rmm":false,"verbosity":1}'}
  """
  def exg_get_global_config, do: :erlang.nif_error(:not_implemented)

  def exg_dmatrix_create_from_file(_file_path, _silent), do: :erlang.nif_error(:not_implemented)

  def exg_dmatrix_create_from_mat(_data, _nrow, _ncol, _missing),
    do: :erlang.nif_error(:not_implemented)

  def exg_dmatrix_create_from_csr(_indptr, _indices, _data, _nrow, _ncol, _missing),
    do: :erlang.nif_error(:not_implemented)
end
