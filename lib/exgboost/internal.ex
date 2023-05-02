defmodule Exgboost.Internal do
  @moduledoc false

  def validate_type!(%Nx.Tensor{} = tensor, type) do
    unless Nx.type(tensor) == type do
      raise ArgumentError,
            "invalid type #{inspect(Nx.type(tensor))}, vector type" <>
              " must be #{inspect(type)}"
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

  def unwrap!({:ok, val}), do: val
  def unwrap!({:error, reason}), do: raise(reason)
end
