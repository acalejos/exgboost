defmodule Exgboost.ArrayInterface do
  alias __MODULE__
  @moduledoc false
  @typedoc """
  The XGBoost C API uses and is moving towards mainly supporting the use of
  JSON-Encoded NumPy ArrayyInterface format to pass data to and from the C API. This struct
  is used to represent the ArrayInterface format.

  If you wish to use the Exgboost.NIF library directly, this will be the desired format
  to pass Nx.Tensors to the NIFs. Use of the Exgboost.NIF library directly is not recommended
  unless you are familiar with the XGBoost C API and the Exgboost.NIF library.

  See https://numpy.org/doc/stable/reference/arrays.interface.html for more information on
  the ArrayInterface protocol.
  """
  @type t :: %ArrayInterface{
          typestr: String.t(),
          shape: tuple(),
          address: pos_integer(),
          readonly: boolean(),
          tensor: Nx.Tensor.t()
        }

  @enforce_keys [:typestr, :shape, :address, :readonly]
  defstruct [
    :typestr,
    :shape,
    :address,
    :readonly,
    :tensor,
    version: 3
  ]

  defimpl Jason.Encoder do
    def encode(
          %{
            typestr: typestr,
            shape: shape,
            address: address,
            readonly: readonly,
            version: version
          },
          opts
        ) do
      Jason.Encode.map(
        %{
          typestr: typestr,
          shape: Tuple.to_list(shape),
          data: [address, readonly],
          version: version
        },
        opts
      )
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(
          %{
            typestr: typestr,
            shape: shape,
            address: address,
            readonly: readonly,
            version: version
          },
          opts
        ) do
      concat([
        "#ArrayInterface<",
        line(),
        to_doc(
          %{
            typestr: typestr,
            shape: Tuple.to_list(shape),
            data: [address, readonly],
            version: version
          },
          opts
        ),
        line(),
        ">"
      ])
    end
  end

  @doc """
  This function is used to convert Nx.Tensors to the ArrayInterface format.

  Example:
    iex> Exgboost.array_interface(Nx.tensor([[1,2,3],[4,5,6]]))
        #ArrayInterface<
        %{data: [4418559984, true], shape: [2, 3], typestr: "<i8", version: 3}
  """
  @spec array_interface(Nx.Tensor.t()) :: %Exgboost.ArrayInterface{}
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

    tensor_addr =
      Exgboost.NIF.get_binary_address(Nx.to_binary(tensor)) |> Exgboost.Internal.unwrap!()

    %ArrayInterface{
      typestr: type_char,
      shape: Nx.shape(tensor),
      address: tensor_addr,
      readonly: true,
      tensor: tensor
    }
  end
end
