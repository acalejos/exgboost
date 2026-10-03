defmodule EXGBoost.ArrayInterface do
  @moduledoc false

  @typedoc """
  The XGBoost C API uses and is moving towards mainly supporting the use of
  JSON-Encoded NumPy ArrayInterface format to pass data to and from the C API. This struct
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
          readonly: boolean(),
          binary: binary() | nil
        }

  @enforce_keys [:typestr, :shape, :readonly]
  defstruct [
    :typestr,
    :shape,
    :readonly,
    :binary,
    version: 3
  ]

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(
          %{
            typestr: typestr,
            shape: shape,
            readonly: readonly,
            version: version
          },
          opts
        ) do
      # Explicitly order keys for consistent output across Elixir/Erlang versions
      data = [
        readonly: readonly,
        shape: Tuple.to_list(shape),
        typestr: typestr,
        version: version
      ]

      concat([
        "#ArrayInterface<",
        line(),
        to_doc(Map.new(data), opts),
        line(),
        ">"
      ])
    end
  end

  def from_map(%{} = interface) do
    interface
    |> Enum.reduce([], fn
      {"data", [_address, readonly]}, acc ->
        [{:readonly, readonly} | acc]

      {:data, [_address, readonly]}, acc ->
        [{:readonly, readonly} | acc]

      {"shape", shape}, acc ->
        [{:shape, List.to_tuple(shape)} | acc]

      {:shape, shape}, acc ->
        [{:shape, List.to_tuple(shape)} | acc]

      {"typestr", typestr}, acc ->
        [{:typestr, typestr} | acc]

      {:typestr, typestr}, acc ->
        [{:typestr, typestr} | acc]

      {"version", version}, acc ->
        [{:version, version} | acc]

      {:version, version}, acc ->
        [{:version, version} | acc]

      {"binary", binary}, acc ->
        [{:binary, binary} | acc]

      {:binary, binary}, acc ->
        [{:binary, binary} | acc]

      {_key, _value}, acc ->
        acc
    end)
    |> then(&struct(__MODULE__, &1))
  end

  @doc """
  This function is used to convert Nx.Tensors to the ArrayInterface format.

  ## Examples

      iex(1)> tensor = EXGBoost.ArrayInterface.from_tensor(Nx.tensor([[1,2,3],[4,5,6]]))
      iex(2)> tensor.version
      3
      iex(3)> tensor.typestr
      "<i4"
      iex(4)> tensor.shape
      {2, 3}
      iex(5)> tensor.binary
      <<1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 4, 0, 0, 0, 5, 0, 0, 0, 6, 0, 0, 0>>
      iex(6)>
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

    binary = Nx.to_binary(tensor)

    %__MODULE__{
      typestr: type_char,
      shape: Nx.shape(tensor),
      readonly: true,
      binary: binary
    }
  end

  @doc """
  Parses a NumPy Array Interface `typestr` into an Nx type.

  Returns `{:ok, type}` on success or `{:error, reason}` on failure.

  Only little-endian multi-byte numeric values and byte-order-independent
  single-byte values are supported.

  ## Examples

      iex> EXGBoost.ArrayInterface.parse_typestr("<f4")
      {:ok, {:f, 32}}

      iex> EXGBoost.ArrayInterface.parse_typestr("<i8")
      {:ok, {:s, 64}}

      iex> EXGBoost.ArrayInterface.parse_typestr("<x4")
      {:error, "Unsupported typestr type code \\"x\\" in \\"<x4\\""}

  """
  @spec parse_typestr(String.t()) ::
          {:ok, Nx.Type.t()} | {:error, String.t()}
  def parse_typestr(typestr) when is_binary(typestr) do
    with {:ok, endian, type_code, byte_count} <- split_typestr(typestr),
         :ok <- validate_endianness(endian, byte_count, typestr),
         {:ok, type_atom} <- parse_type_code(type_code, typestr),
         {:ok, nx_type} <- normalize_type(type_atom, byte_count, typestr) do
      {:ok, nx_type}
    end
  end

  @doc """
  Parses a NumPy Array Interface `typestr` into an Nx type.

  Raises `ArgumentError` when the value is malformed or unsupported.
  """
  @spec parse_typestr!(String.t()) :: Nx.Type.t()
  def parse_typestr!(typestr) when is_binary(typestr) do
    case parse_typestr(typestr) do
      {:ok, type} ->
        type

      {:error, reason} ->
        raise ArgumentError, reason
    end
  end

  @spec get_tensor(EXGBoost.ArrayInterface.t()) :: Nx.Tensor.t()
  def get_tensor(%__MODULE__{binary: binary, typestr: typestr, shape: shape})
      when is_binary(binary) do
    nx_type = parse_typestr!(typestr)
    Nx.from_binary(binary, nx_type) |> Nx.reshape(shape)
  end

  def get_tensor(%__MODULE__{binary: nil}) do
    raise ArgumentError, """
    Cannot reconstruct tensor from ArrayInterface without binary data.

    ArrayInterface instances must include the binary data field.
    If you're seeing this error, ensure the ArrayInterface was created with
    from_tensor/1 or includes binary data from a NIF (like get_quantile_cut).
    """
  end

  @spec to_tuple(EXGBoost.ArrayInterface.t()) ::
          {binary() | nil, String.t(), [integer()], boolean()}
  def to_tuple(%__MODULE__{binary: binary, typestr: typestr, shape: shape, readonly: readonly}) do
    {binary, typestr, Tuple.to_list(shape), readonly}
  end

  defp split_typestr(<<endian, type_code, bytes::binary>> = typestr)
       when endian in [?<, ?>, ?|] and bytes != "" do
    case Integer.parse(bytes) do
      {byte_count, ""} when byte_count > 0 ->
        {:ok, endian, type_code, byte_count}

      _ ->
        {:error,
         "Invalid byte count in #{inspect(typestr)}; " <>
           ~s(expected a positive integer, for example "<f4")}
    end
  end

  defp split_typestr(typestr) do
    {:error,
     "Invalid typestr #{inspect(typestr)}; " <>
       ~s(expected a value such as "<f4", "<i8", or "|u1")}
  end

  defp validate_endianness(?>, _byte_count, typestr) do
    {:error,
     "Big-endian typestr #{inspect(typestr)} is unsupported; " <>
       "the binary must be byte-swapped before constructing the Nx tensor"}
  end

  defp validate_endianness(?|, byte_count, typestr)
       when byte_count != 1 do
    {:error,
     "Byte-order-independent marker \"|\" is invalid for " <>
       "multi-byte numeric type #{inspect(typestr)}"}
  end

  defp validate_endianness(_endian, _byte_count, _typestr), do: :ok

  defp parse_type_code(?i, _typestr), do: {:ok, :s}
  defp parse_type_code(?u, _typestr), do: {:ok, :u}
  defp parse_type_code(?f, _typestr), do: {:ok, :f}
  defp parse_type_code(?c, _typestr), do: {:ok, :c}

  defp parse_type_code(type_code, typestr) do
    {:error,
     "Unsupported typestr type code " <>
       "#{inspect(<<type_code>>)} in #{inspect(typestr)}"}
  end

  defp normalize_type(type_atom, byte_count, typestr) do
    type = {type_atom, byte_count * 8}

    try do
      {:ok, Nx.Type.normalize!(type)}
    rescue
      ArgumentError ->
        {:error,
         "typestr #{inspect(typestr)} maps to unsupported Nx type " <>
           inspect(type)}
    end
  end
end
