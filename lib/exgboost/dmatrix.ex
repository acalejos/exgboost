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
  @enforce_keys [:ref, :format]
  defstruct [:ref, :format]

  @str_features [:feature_name, :feature_type]
  @meta_features [
    :label,
    :weight,
    :base_margin,
    :group,
    :label_upper_bound,
    :label_lower_bound,
    :feature_weights
  ]
  @config_features [:missing, :nthread]
  @behaviour Access
  @impl Access
  def fetch(dmatrix, feature)
      when feature in [
             "label",
             "weight",
             "base_margin",
             "label_lower_bound",
             "label_upper_bound",
             "feature_weights"
           ],
      do: {:ok, Exgboost.NIF.dmatrix_get_float_info(dmatrix.ref, feature)}

  def fetch(dmatrix, "group"),
    do: {:ok, Exgboost.NIF.dmatrix_get_uint_info(dmatrix.ref, "group_ptr")}

  def fetch(dmatrix, "rows"),
    do: {:ok, Exgboost.NIF.dmatrix_num_row(dmatrix.ref)}

  def fetch(dmatrix, "cols"),
    do: {:ok, Exgboost.NIF.dmatrix_num_col(dmatrix.ref)}

  def fetch(dmatrix, "non_missing"),
    do: {:ok, Exgboost.NIF.dmatrix_num_non_missing(dmatrix.ref)}

  def fetch(dmatrix, "data"),
    do: {:ok, Exgboost.NIF.dmatrix_get_data_as_csr(dmatrix.ref, Jason.encode!(%{}))}

  def fetch(_dmatrix, _other), do: :error

  @impl Access
  def get_and_update(dmatrix, feature, fun)
      when feature in [
             "label",
             "weight",
             "base_margin",
             "label_lower_bound",
             "label_upper_bound",
             "feature_weights",
             "group"
           ] and is_function(fun, 1) do
    current =
      if feature == "group" do
        Exgboost.NIF.dmatrix_get_uint_info(dmatrix.ref, "group_ptr")
      else
        Exgboost.NIF.dmatrix_get_float_info(dmatrix.ref, feature)
      end

    case fun.(current) do
      {current_value, new_value} ->
        data_interface = Exgboost.Internal.array_interface(new_value) |> Jason.encode!()

        case Exgboost.NIF.dmatrix_set_info_from_interface(dmatrix.ref, feature, data_interface) do
          :ok ->
            {current_value, dmatrix}

          {:error, msg} ->
            raise msg
        end

      :pop ->
        raise "Pop not a supported operation for DMatrix"

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  def get_and_update(_dmatrix, feature, _fun) do
    raise "Feature #{inspect(feature)} not supported"
  end

  @impl Access
  def pop(_data, _key) do
    raise "Pop not a supported operation for DMatrix"
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(dmatrix, _opts) do
      {indptr, indices, data} = dmatrix["data"] |> Exgboost.Internal.unwrap!()
      num_rows = dmatrix["rows"] |> Exgboost.Internal.unwrap!()
      num_cols = dmatrix["cols"] |> Exgboost.Internal.unwrap!()
      non_missing = dmatrix["non_missing"] |> Exgboost.Internal.unwrap!()
      group = dmatrix["group"] |> Exgboost.Internal.unwrap!()

      concat([
        "DMatrix<",
        line(),
        "  {#{num_rows}x#{num_cols}x#{non_missing}}",
        line(),
        if(group != nil, do: "  group: #{inspect(group)}"),
        line(),
        "  indptr: #{inspect(indptr)}",
        line(),
        "  indices: #{inspect(indices)}",
        line(),
        "  data: #{inspect(data)}",
        line(),
        ">"
      ])
    end
  end

  def get_args_groups(args, opts) when is_list(opts) and is_list(args) do
    Enum.reduce(opts, [], fn opt, acc ->
      case opt do
        :config ->
          [Keyword.take(args, @config_features) | acc]

        :format ->
          [Keyword.take(args, [:format]) | acc]

        :meta ->
          [
            Keyword.take(args, @meta_features)
            | acc
          ]

        :str ->
          [Keyword.take(args, @str_features) | acc]

        true ->
          raise ArgumentError, "Unknown option: #{inspect(opt)}"
      end
    end)
    |> Enum.reverse()
    |> List.to_tuple()
  end
end
