defmodule Exgboost.Internal do
  @moduledoc false
  alias Exgboost.Booster
  alias Exgboost.DMatrix

  def validate_type!(%Nx.Tensor{} = tensor, type) do
    unless Nx.type(tensor) == type do
      raise ArgumentError,
            "invalid type #{inspect(Nx.type(tensor))}, vector type" <>
              " must be #{inspect(type)}"
    end
  end

  def validate_features!(%Booster{} = booster, %DMatrix{} = dmatrix) do
    unless dmatrix["rows"] == 0 do
      booster_names = booster["feature_names"]
      booster_types = booster["feature_types"]
      dmatrix_names = dmatrix["feature_names"]
      dmatrix_types = dmatrix["feature_types"]

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

  def array_interface(%Nx.Tensor{} = tensor) do
    type_char =
      case Nx.type(tensor) do
        {:s, width} ->
          "<i#{div(width, 8)}"

        # TODO: Use V typestr to handle other data types
        {:bf, _width} ->
          raise ArgumentError,
                "Invalid tensor type -- #{inspect(Nx.type(tensor))} not supported by Exgboost"

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

  def update(%Booster{} = booster, %DMatrix{} = dmatrix, iteration) when is_integer(iteration) do
    Exgboost.NIF.booster_update_one_iter(booster.ref, dmatrix.ref, iteration) |> unwrap!()
  end

  def update(%Booster{} = booster, %DMatrix{} = dmatrix, objective)
      when is_function(objective, 2) do
    pred = Exgboost.predict(booster, dmatrix, output_margin: true, training: true)
    {grad, hess} = objective.(pred, dmatrix)
    boost(booster, dmatrix, grad, hess)
  end

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

  def _train(%Booster{} = booster, %DMatrix{} = dmat, opts \\ []) do
    opts = Keyword.validate!(opts, [:obj, num_boost_rounds: 10])
    objective = Keyword.get(opts, :obj)
    start_iteration = 0
    num_boost_rounds = Keyword.fetch!(opts, :num_boost_rounds)

    for i <- start_iteration..(num_boost_rounds - 1) do
      # Exgboost.NIF.booster_update_one_iter(booster.ref, dmat.ref, i)
      if objective do
        update(booster, dmat, objective)
      else
        update(booster, dmat, i)
      end
    end

    booster
  end

  def set_dmatrix_params(dmat, opts) do
    opts =
      Keyword.validate!(opts, [
        :label,
        :weight,
        :base_margin,
        :group,
        :label_upper_bound,
        :label_lower_bound,
        :feature_weights
      ])

    {meta_opts, str_opts} = DMatrix.get_args_groups(opts, [:meta, :str])

    Enum.each(meta_opts, fn {key, value} ->
      data_interface = array_interface(value) |> Jason.encode!()
      Exgboost.NIF.dmatrix_set_info_from_interface(dmat.ref, Atom.to_string(key), data_interface)
    end)

    Enum.each(str_opts, fn {key, value} ->
      Exgboost.NIF.dmatrix_set_str_feature_info(dmat.ref, Atom.to_string(key), value)
    end)

    dmat
  end

  @doc """
  Need to implement this because XGBoost expects NaN to be encoded as "NaN" without being
  a string, so if we pass string NaN to XGBoost, it will fail.

  This allows the user to use Nx.Constants.nan() and have it work as expected.
  """
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

  def unwrap!({:ok, val}), do: val
  def unwrap!({:error, reason}), do: raise(reason)
  def unwrap!(:ok), do: :ok
end
