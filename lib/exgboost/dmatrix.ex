defmodule Exgboost.DMatrix do
  @moduledoc """
  Parameters
  ----------
  data :
      Data source of DMatrix.
  label :
      Label of the training data.
  weight :
      Weight for each instance.

       .. note::

           For ranking task, weights are per-group.  In ranking task, one weight
           is assigned to each group (not each data point). This is because we
           only care about the relative ordering of data points within each group,
           so it doesn't make sense to assign weights to individual data points.

  base_margin :
      Base margin used for boosting from existing model.
  missing :
      Value in the input data which needs to be present as a missing value. If
      None, defaults to np.nan.
  silent :
      Whether print messages during construction
  feature_names :
      Set names for features.
  feature_types :

      Set types for features.  When `enable_categorical` is set to `True`, string
      "c" represents categorical data type while "q" represents numerical feature
      type. For categorical features, the input is assumed to be preprocessed and
      encoded by the users. The encoding can be done via
      :py:class:`sklearn.preprocessing.OrdinalEncoder` or pandas dataframe
      `.cat.codes` method. This is useful when users want to specify categorical
      features without having to construct a dataframe as input.

  nthread :
      Number of threads to use for loading data when parallelization is
      applicable. If -1, uses maximum threads available on the system.
  group :
      Group size for all ranking group.
  qid :
      Query ID for data samples, used for ranking.
  label_lower_bound :
      Lower bound for survival training.
  label_upper_bound :
      Upper bound for survival training.
  feature_weights :
      Set feature weights for column sampling.
  enable_categorical :

      .. versionadded:: 1.3.0

      .. note:: This parameter is experimental

      Experimental support of specializing for categorical features.  Do not set
      to True unless you are interested in development. Also, JSON/UBJSON
      serialization format is required.

  """
  alias __MODULE__
  alias Exgboost.Internal

  @enforce_keys [
    :ref,
    :format
  ]
  defstruct [
    :ref,
    :format,
    :label,
    :weight,
    :base_margin,
    :group,
    :label_upper_bound,
    :label_lower_bound,
    :feature_weights,
    :missing,
    :nthread,
    :feature_names,
    :feature_types
  ]

  def get_float_info(dmatrix, feature)
      when feature in [
             "label",
             "weight",
             "base_margin",
             "label_lower_bound",
             "label_upper_bound",
             "feature_weights"
           ],
      do: Exgboost.NIF.dmatrix_get_float_info(dmatrix.ref, feature) |> Internal.unwrap!()

  def get_group(dmatrix), do: get_uint_info(dmatrix, "group")

  def get_uint_info(dmatrix, "group"),
    do: Exgboost.NIF.dmatrix_get_uint_info(dmatrix.ref, "group_ptr") |> Internal.unwrap!()

  def get_num_rows(dmatrix),
    do: Exgboost.NIF.dmatrix_num_row(dmatrix.ref) |> Internal.unwrap!()

  def get_num_cols(dmatrix),
    do: Exgboost.NIF.dmatrix_num_col(dmatrix.ref) |> Internal.unwrap!()

  def get_num_non_missing(dmatrix),
    do: Exgboost.NIF.dmatrix_num_non_missing(dmatrix.ref) |> Internal.unwrap!()

  def get_data(dmatrix),
    do:
      Exgboost.NIF.dmatrix_get_data_as_csr(dmatrix.ref, Jason.encode!(%{})) |> Internal.unwrap!()

  def get_feature_names(dmatrix),
    do:
      Exgboost.NIF.dmatrix_get_str_feature_info(dmatrix.ref, "feature_name") |> Internal.unwrap!()

  def get_feature_types(dmatrix),
    do:
      Exgboost.NIF.dmatrix_get_str_feature_info(dmatrix.ref, "feature_type") |> Internal.unwrap!()

  def set_params(dmat, opts) do
    options = Internal.dmatrix_str_feature_opts() ++ Internal.dmatrix_meta_feature_opts()
    opts = Keyword.validate!(opts, options)

    {meta_opts, opts} = Keyword.split(opts, Internal.dmatrix_meta_feature_opts())
    {str_opts, _opts} = Keyword.split(opts, Internal.dmatrix_str_feature_opts())

    args = Enum.into(Keyword.merge(meta_opts, str_opts), %{})

    Enum.each(meta_opts, fn {key, value} ->
      data_interface = Exgboost.Internal.array_interface(value) |> Jason.encode!()

      Exgboost.NIF.dmatrix_set_info_from_interface(
        dmat.ref,
        Atom.to_string(key),
        data_interface
      )
    end)

    Enum.each(str_opts, fn {key, value} ->
      Exgboost.NIF.dmatrix_set_str_feature_info(dmat.ref, Atom.to_string(key), value)
    end)

    struct(dmat, args)
  end

  @doc """
  Slice the DMatrix and return a new DMatrix that only contains rindex.
  """
  def slice(dmat, %Nx.Tensor{shape: {_rows}} = r_index, opts \\ [])
      when is_list(opts) do
    opts = Keyword.validate!(opts, allow_groups: false)
    allow_groups = Keyword.fetch!(opts, :allow_groups)
    Exgboost.NIF.dmatrix_slice(dmat.ref, Nx.to_binary(r_index), allow_groups)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(dmatrix, _opts) do
      {indptr, indices, data} = DMatrix.get_data(dmatrix)

      concat([
        "#DMatrix<",
        line(),
        "  {#{DMatrix.get_num_rows(dmatrix)}x#{DMatrix.get_num_cols(dmatrix)}x#{DMatrix.get_num_non_missing(dmatrix)}}",
        line(),
        if(DMatrix.get_group(dmatrix) != nil,
          do: "  group: #{inspect(DMatrix.get_group(dmatrix))}"
        ),
        line(),
        "  indptr: #{inspect(Nx.tensor(indptr))}",
        line(),
        "  indices: #{inspect(Nx.tensor(indices))}",
        line(),
        "  data: #{inspect(Nx.tensor(data))}",
        line(),
        ">"
      ])
    end
  end

  @doc """
  Create a DMatrix from a file.

  Refer to https://xgboost.readthedocs.io/en/latest/tutorials/external_memory.html#text-file-inputs
  for proper formatting of the file and the options.

  This function will URI encode the filepath according to the URI scheme defined in
  XGBoost's documentation.
  """
  def from_file(filepath, opts) when is_binary(filepath) and is_list(opts) do
    opts =
      Keyword.validate!(opts,
        label_column: nil,
        cacheprefix: nil,
        format: :dense,
        ext: :auto,
        silent: 1
      )

    if not (File.exists?(filepath) and File.regular?(filepath)) do
      raise ArgumentError, "File must exist and be a regular file"
    end

    {file_format, opts} = Keyword.pop!(opts, :ext)
    {silent, opts} = Keyword.pop!(opts, :silent)
    {format, opts} = Keyword.pop!(opts, :format)
    {label_column, opts} = Keyword.pop!(opts, :label_column)
    {cacheprefix, opts} = Keyword.pop!(opts, :cacheprefix)

    ext =
      case file_format do
        :libsvm -> "libsvm"
        :csv -> "csv"
        :auto -> "auto"
        _ -> raise ArgumentError, "Invalid file format"
      end

    uri = "#{filepath}?format=#{ext}"

    if file_format != :csv and not is_nil(label_column) do
      if silent == 1 do
        IO.warn("label_column only be specified for CSV files -- ignoring...")
      else
        raise ArgumentError, "label_column only be specified for CSV files"
      end
    end

    if not is_nil(cacheprefix) and not File.exists?(cacheprefix) do
      if silent == 1 do
        IO.warn("cacheprefix file not found -- ignoring...")
      else
        raise ArgumentError, "cacheprefix file not found"
      end
    end

    uri =
      if not is_nil(label_column) and file_format == :csv do
        uri <> "&label_column=#{label_column}"
      else
        uri
      end

    uri =
      if not is_nil(cacheprefix) and File.exists?(cacheprefix) and File.regular?(cacheprefix) do
        uri <> "#cacheprefix=#{cacheprefix}"
      else
        uri
      end

    dmat =
      Exgboost.NIF.dmatrix_create_from_file(
        uri,
        silent
      )
      |> Internal.unwrap!()

    set_params(%DMatrix{ref: dmat, format: format}, opts)
  end

  def from_tensor(_tensor, _opts \\ [])

  def from_tensor(%Nx.Tensor{} = tensor, opts) when is_list(opts) do
    opts = Keyword.validate!(opts, Internal.dmatrix_feature_opts())

    {config_opts, opts} = Keyword.split(opts, Internal.dmatrix_config_feature_opts())
    config_opts = Keyword.validate!(config_opts, missing: Nx.Constants.nan(), nthread: 0)
    {format_opts, opts} = Keyword.split(opts, Internal.dmatrix_format_feature_opts())

    config = Enum.into(config_opts, %{}, fn {key, value} -> {Atom.to_string(key), value} end)
    format = Keyword.fetch!(format_opts, :format)

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(
        Jason.encode!(Internal.array_interface(tensor)),
        Jason.encode!(config)
      )
      |> Internal.unwrap!()

    set_params(%DMatrix{ref: dmat, format: format}, opts)
  end

  def from_tensor(%Nx.Tensor{} = x, %Nx.Tensor{} = y) do
    from_tensor(x, y, [])
  end

  def from_tensor(%Nx.Tensor{shape: x_shape}, %Nx.Tensor{shape: {y_shape}}, _opts)
      when is_tuple(x_shape) and elem(x_shape, 0) != elem(y_shape, 0) do
    raise ArgumentError,
          "x and y must have the same number of rows, got #{elem(x_shape, 0)} and #{elem(y_shape, 0)}"
  end

  def from_tensor(%Nx.Tensor{shape: x_shape} = x, %Nx.Tensor{shape: y_shape} = y, opts)
      when is_tuple(x_shape) and elem(x_shape, 0) == elem(y_shape, 0) do
    if Keyword.has_key?(opts, :label) do
      raise ArgumentError, "label must not be specified as an opt if y is provided"
    end

    opts = Keyword.put_new(opts, :label, y)
    from_tensor(x, opts)
  end

  def from_csr(
        %Nx.Tensor{} = indptr,
        %Nx.Tensor{} = indices,
        %Nx.Tensor{} = data,
        n,
        opts \\ []
      )
      when is_integer(n) and n > 0 do
    from_csr({indptr, indices, data, n}, opts)
  end

  def from_csr(
        {%Nx.Tensor{} = indptr, %Nx.Tensor{} = indices, %Nx.Tensor{} = data, n},
        opts \\ []
      )
      when is_integer(n) and n > 0 do
    opts = Keyword.validate!(opts, Internal.dmatrix_feature_opts())

    {config_opts, opts} = Keyword.split(opts, Internal.dmatrix_config_feature_opts())
    config_opts = Keyword.validate!(config_opts, missing: Nx.Constants.nan(), nthread: 0)
    {format_opts, opts} = Keyword.split(opts, Internal.dmatrix_format_feature_opts())

    config = Enum.into(config_opts, %{}, fn {key, value} -> {Atom.to_string(key), value} end)
    format = Keyword.fetch!(format_opts, :format)

    if format not in [:csr, :csc] do
      raise ArgumentError, "Sparse format must be :csr or :csc"
    end

    dmat =
      Exgboost.NIF.dmatrix_create_from_sparse(
        Jason.encode!(Internal.array_interface(indptr)),
        Jason.encode!(Internal.array_interface(indices)),
        Jason.encode!(Internal.array_interface(data)),
        n,
        Jason.encode!(config),
        Atom.to_string(format)
      )
      |> Internal.unwrap!()

    set_params(%DMatrix{ref: dmat, format: format}, opts)
  end
end

defmodule Exgboost.ProxyDMatrix do
  alias __MODULE__
  @enforce_keys [:ref]
  defstruct [:ref]

  def proxy_dmatrix() do
    p_ref = Exgboost.NIF.proxy_dmatrix_create()
    %ProxyDMatrix{ref: p_ref}
  end

  def set_params(%ProxyDMatrix{} = dmat, opts) do
    Exgboost.DMatrix.set_params(dmat, opts)
  end
end
