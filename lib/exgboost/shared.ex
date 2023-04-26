defmodule Exgboost.Shared do
  @moduledoc false

  def validate_type!(%Nx.Tensor{} = tensor, type) do
    unless Nx.type(tensor) == type do
      raise ArgumentError,
            "invalid type #{inspect(Nx.type(tensor))}, vector type" <>
              " must be #{inspect(type)}"
    end
  end

  def to_array_interface(%Nx.Tensor{} = tensor) do
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

    # %lu needs to be removed as a string within the encoding since it will be used as a format
    # specifier within the C side of the NIF. We pass the tensor as a binary and will need to
    # put the memory location into that format specifier.
    %{
      version: 3,
      typestr: type_char,
      shape: Tuple.to_list(Nx.shape(tensor)),
      data: ["%lu", false]
    }
    |> Jason.encode!()
    |> String.replace(~s(\"%lu\"), "%lu")
  end

  def unwrap!({:ok, val}), do: val
  def unwrap!({:error, reason}), do: raise(reason)
end
