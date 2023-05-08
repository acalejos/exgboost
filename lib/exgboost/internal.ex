defmodule Exgboost.Internal do
  @moduledoc false
  alias Exgboost.Booster
  alias Exgboost.DMatrix

  def dmatrix_feature_opts,
    do:
      dmatrix_str_feature_opts() ++
        dmatrix_meta_feature_opts() ++
        dmatrix_config_feature_opts() ++ dmatrix_format_feature_opts()

  def dmatrix_str_feature_opts, do: [:feature_name, :feature_type]

  def dmatrix_format_feature_opts(), do: [:format]

  def dmatrix_meta_feature_opts,
    do: [
      :label,
      :weight,
      :base_margin,
      :group,
      :label_upper_bound,
      :label_lower_bound,
      :feature_weights
    ]

  def dmatrix_config_feature_opts, do: [:nthread, :missing]

  def validate_type!(%Nx.Tensor{} = tensor, type) do
    unless Nx.type(tensor) == type do
      raise ArgumentError,
            "invalid type #{inspect(Nx.type(tensor))}, vector type" <>
              " must be #{inspect(type)}"
    end
  end

  def validate_features!(%Booster{} = booster, %DMatrix{} = dmatrix) do
    unless DMatrix.get_num_rows(dmatrix) == 0 do
      booster_names = Booster.get_feature_names(booster)
      booster_types = Booster.get_feature_types(booster)
      dmatrix_names = DMatrix.get_feature_names(dmatrix)
      dmatrix_types = DMatrix.get_feature_types(dmatrix)

      if dmatrix_names == nil and booster_names != nil do
        raise ArgumentError,
              "training data did not have the following fields: #{inspect(booster_names)}"
      end

      if dmatrix_types == nil and booster_types != nil do
        raise ArgumentError,
              "training data did not have the following types: #{inspect(booster_types)}"
      end

      if booster_names != dmatrix_names do
        booster_name_set = MapSet.new(booster_names)
        dmatrix_name_set = MapSet.new(dmatrix_names)
        dmatrix_missing = MapSet.difference(booster_name_set, dmatrix_name_set)
        my_missing = MapSet.difference(dmatrix_name_set, booster_name_set)
        msg = "feature_names mismatch: #{inspect(booster_names)} #{inspect(dmatrix_names)}"

        msg =
          if MapSet.size(dmatrix_missing) != 0 do
            msg <> "\nexpected #{inspect(dmatrix_missing)} in input data"
          else
            msg
          end

        msg =
          if MapSet.size(my_missing) != 0 do
            msg <> "\ntraining data did not have the following fields: #{inspect(my_missing)}"
          else
            msg
          end

        raise ArgumentError, msg
      end
    end
  end

  def get_xgboost_data_type(%Nx.Tensor{} = tensor) do
    case Nx.type(tensor) do
      {:f, 32} ->
        {:ok, 1}

      {:f, 64} ->
        {:ok, 2}

      {:u, 32} ->
        {:ok, 3}

      {:u, 64} ->
        {:ok, 4}

      true ->
        {:error,
         "invalid type #{inspect(Nx.type(tensor))}\nxgboost DMatrix only supports data types of float32, float64, uint32, and uint64"}
    end
  end

  def set_params(_dmatrix, _opts \\ [])

  def set_params(%DMatrix{} = dmat, opts) do
    Exgboost.DMatrix.set_params(dmat, opts)
  end

  def set_params(%Booster{} = booster, opts) do
    Exgboost.Booster.set_params(booster, opts)
  end

  @doc """
  Update for one iteration, with objective function calculated internally.

  If an objective function is provided rather than a number of iterations, this
  updates for one iteration, with objective function defined by the user.

  See [Custom Objective](https://xgboost.readthedocs.io/en/latest/tutorials/custom_metric_obj.html) for details.
  """
  def update(%Booster{} = booster, %DMatrix{} = dmatrix, iteration) when is_integer(iteration) do
    Exgboost.NIF.booster_update_one_iter(booster.ref, dmatrix.ref, iteration) |> unwrap!()
  end

  def update(%Booster{} = booster, %DMatrix{} = dmatrix, objective)
      when is_function(objective, 2) do
    pred = predict(booster, dmatrix, output_margin: true, training: true)
    {grad, hess} = objective.(pred, dmatrix)
    boost(booster, dmatrix, grad, hess)
  end

  @doc """
  Boost the booster for one iteration, with customized gradient statistics.
  """
  def boost(
        %Booster{} = booster,
        %DMatrix{} = dmatrix,
        %Nx.Tensor{} = grad,
        %Nx.Tensor{} = hess
      ) do
    validate_type!(grad, {:f, 32})
    validate_type!(hess, {:f, 32})

    if Nx.shape(grad) != Nx.shape(hess) do
      raise ArgumentError,
            "grad and hess must have the same shape, got #{inspect(Nx.shape(grad))} and #{inspect(Nx.shape(hess))}"
    end

    Exgboost.NIF.booster_boost_one_iter(
      booster.ref,
      dmatrix.ref,
      Nx.to_binary(grad),
      Nx.to_binary(hess)
    )
  end

  # Need to implement this because XGBoost expects NaN to be encoded as "NaN" without being
  # a string, so if we pass string NaN to XGBoost, it will fail.
  # This allows the user to use Nx.Constants.nan() and have it work as expected.
  defimpl Jason.Encoder, for: Nx.Tensor do
    def encode(%Nx.Tensor{data: %Nx.BinaryBackend{state: <<0x7FC0::16-native>>}}, _opts),
      do: "NaN"

    def encode(%Nx.Tensor{data: %Nx.BinaryBackend{state: <<0x7E00::16-native>>}}, _opts),
      do: "NaN"

    def encode(%Nx.Tensor{data: %Nx.BinaryBackend{state: <<0x7FC00000::32-native>>}}, _opts),
      do: "NaN"

    def encode(
          %Nx.Tensor{data: %Nx.BinaryBackend{state: <<0x7FF8000000000000::64-native>>}},
          _opts
        ),
        do: "NaN"
  end

  @doc """
  The XGBoost C API uses and is moving towards mainly supporting the use of
  JSON-Encoded NumPy ArrayyInterface format to pass data to and from the C API. This function
  is used to convert Nx.Tensors to the ArrayInterface format.

  If you wish to use the Exgboost.NIF library directly, this will be the desired format
  to pass Nx.Tensors to the NIFs. Use of the Exgboost.NIF library directly is not recommended
  unless you are familiar with the XGBoost C API and the Exgboost.NIF library.

  See https://numpy.org/doc/stable/reference/arrays.interface.html for more information on
  the ArrayInterface protocol.

  Example:
    iex> Exgboost.array_interface(Nx.tensor([[1,2,3],[4,5,6]]))
        #ArrayInterface<
        %{data: [4418559984, true], shape: [2, 3], typestr: "<i8", version: 3}
        >
  """
  @spec array_interface(%Nx.Tensor{}) :: %Exgboost.ArrayInterface{}
  def array_interface(%Nx.Tensor{type: t_type} = tensor) do
    type_char =
      case t_type do
        {:s, width} ->
          "<i#{div(width, 8)}"

        # TODO: Use V typestr to handle other data types
        {:bf, _width} ->
          raise ArgumentError,
                "Invalid tensor type -- #{inspect(t_type)} not supported by Exgboost"

        {tensor_type, type_width} ->
          "<#{Atom.to_string(tensor_type)}#{div(type_width, 8)}"
      end

    tensor_addr = Exgboost.NIF.get_binary_address(Nx.to_binary(tensor)) |> unwrap!()

    %Exgboost.ArrayInterface{
      typestr: type_char,
      shape: Nx.shape(tensor),
      address: tensor_addr,
      readonly: true,
      tensor: tensor
    }
  end

  def train(%DMatrix{} = dmat, opts \\ []) do
    opts = Keyword.validate!(opts, [:obj, num_boost_rounds: 10, params: %{}])

    {booster_opts, opts} = Keyword.pop!(opts, :params)
    # TODO: Find exhaustive list of params to use String.to_existing_atom()
    booster_opts = Keyword.new(booster_opts, fn {key, value} -> {key, value} end)

    bst = Exgboost.Booster.booster(dmat, booster_opts)
    opts = Keyword.validate!(opts, [:obj, num_boost_rounds: 10])
    objective = Keyword.get(opts, :obj)
    start_iteration = 0
    num_boost_rounds = Keyword.fetch!(opts, :num_boost_rounds)

    for i <- start_iteration..(num_boost_rounds - 1) do
      if objective do
        update(bst, dmat, objective)
      else
        update(bst, dmat, i)
      end
    end

    bst
  end

  def predict(%Booster{} = booster, %DMatrix{} = data, opts \\ []) do
    opts =
      Keyword.validate!(opts,
        output_margin: false,
        pred_leaf: false,
        pred_contribs: false,
        approx_contribs: false,
        pred_interactions: false,
        validate_features: true,
        training: false,
        iteration_range: {0, 0},
        strict_shape: false
      )

    if Keyword.fetch!(opts, :validate_features) do
      Exgboost.Internal.validate_features!(booster, data)
    end

    approx_contribs = Keyword.fetch!(opts, :approx_contribs)

    type_count =
      Keyword.take(opts, [:output_margin, :pred_leaf, :pred_contribs, :pred_interactions])
      |> Keyword.values()
      |> Enum.count(& &1)

    if type_count > 1 do
      raise ArgumentError,
            "Only one of :output_margin, :pred_leaf, :pred_contribs, :pred_interactions can be set to true"
    end

    type =
      cond do
        Keyword.fetch!(opts, :output_margin) ->
          1

        Keyword.fetch!(opts, :pred_contribs) ->
          if approx_contribs, do: 3, else: 2

        Keyword.fetch!(opts, :pred_interactions) ->
          if approx_contribs, do: 5, else: 4

        Keyword.fetch!(opts, :pred_leaf) ->
          6

        true ->
          0
      end

    {left_range, right_range} = Keyword.fetch!(opts, :iteration_range)

    config = %{
      type: type,
      training: Keyword.fetch!(opts, :training),
      iteration_begin: left_range,
      iteration_end: right_range,
      strict_shape: Keyword.fetch!(opts, :strict_shape)
    }

    {shape, preds} =
      Exgboost.NIF.booster_predict_from_dmatrix(booster.ref, data.ref, Jason.encode!(config))
      |> unwrap!()

    Nx.tensor(preds) |> Nx.reshape(shape)
  end

  def unwrap!({:ok, val}), do: val
  def unwrap!({:error, reason}), do: raise(reason)
  def unwrap!(:ok), do: :ok
end
