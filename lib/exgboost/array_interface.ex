defmodule EXGBoost.ArrayInterface do
  @moduledoc false
  alias EXGBoost.Internal

  @typedoc """
  The XGBoost C API uses and is moving towards mainly supporting the use of
  JSON-Encoded NumPy ArrayyInterface format to pass data to and from the C API. This struct
  is used to represent the ArrayInterface format.

  If you wish to use the EXGBoost.NIF library directly, this will be the desired format
  to pass Nx.Tensors to the NIFs. Use of the EXGBoost.NIF library directly is not recommended
  unless you are familiar with the XGBoost C API and the EXGBoost.NIF library.

  See https://numpy.org/doc/stable/reference/arrays.interface.html for more information on
  the ArrayInterface protocol.
  """
  @type t :: %__MODULE__{
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

  def from_map(%{} = interface) do
    interface
    |> Enum.reduce([], fn
      {"data", [address, readonly]}, acc ->
        [{:address, address} | [{:readonly, readonly} | acc]]

      {"shape", shape}, acc ->
        [{:shape, List.to_tuple(shape)} | acc]

      {key, value}, acc ->
        [{String.to_existing_atom(key), value} | acc]
    end)
    |> then(&struct(__MODULE__, &1))
  end

  @doc """
  This function is used to convert Nx.Tensors to the ArrayInterface format.

  Example:
    iex> EXGBoost.from_tensor(Nx.tensor([[1,2,3],[4,5,6]]))
        #ArrayInterface<
        %{data: [4418559984, true], shape: [2, 3], typestr: "<i8", version: 3}
  """
  @spec from_tensor(Nx.Tensor.t()) :: %__MODULE__{}
  def from_tensor(%Nx.Tensor{type: t_type} = tensor) do
    type_char =
      case t_type do
        {:s, width} ->
          "<i#{div(width, 8)}"

        # TODO: Use V typestr to handle other data types
        {:bf, _width} ->
          raise ArgumentError,
                "Invalid tensor type -- #{inspect(t_type)} not supported by EXGBoost"

        {tensor_type, type_width} ->
          "<#{Atom.to_string(tensor_type)}#{div(type_width, 8)}"
      end

    tensor_addr =
      EXGBoost.NIF.get_binary_address(Nx.to_binary(tensor)) |> EXGBoost.Internal.unwrap!()

    %__MODULE__{
      typestr: type_char,
      shape: Nx.shape(tensor),
      address: tensor_addr,
      readonly: true,
      tensor: tensor
    }
  end

  @spec get_tensor(EXGBoost.ArrayInterface.t()) :: Nx.Tensor.t()
  def get_tensor(%__MODULE__{tensor: nil} = arr_int) do
    num_items = arr_int.shape |> Tuple.to_list() |> Enum.product()
    <<_endianess::utf8, char_code::binary-size(1), bytes::binary>> = arr_int.typestr

    nx_type =
      case char_code do
        "i" -> {:s, String.to_integer(bytes) * 8}
        other -> {String.to_existing_atom(other), String.to_integer(bytes) * 8}
      end

    tensor_bin =
      EXGBoost.NIF.get_binary_from_address(arr_int.address, String.to_integer(bytes) * num_items)
      |> Internal.unwrap!()

    Nx.from_binary(
      tensor_bin,
      nx_type
    )
    |> Nx.reshape(arr_int.shape)
  end

  def get_tensor(%__MODULE__{tensor: %Nx.Tensor{} = tensor}) do
    tensor
  end
end
