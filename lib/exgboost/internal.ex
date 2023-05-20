defmodule EXGBoost.Internal do
  @moduledoc false
  alias EXGBoost.Booster
  alias EXGBoost.DMatrix

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
    EXGBoost.DMatrix.set_params(dmat, opts)
  end

  def set_params(%Booster{} = booster, opts) do
    EXGBoost.Booster.set_params(booster, opts)
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

  def unwrap!({:ok, val}), do: val
  def unwrap!({:error, reason}), do: raise(reason)
  def unwrap!(:ok), do: :ok
end
