defmodule Exgboost.ArrayInterface do
  @moduledoc false
  @type shape :: tuple()
  @type typestr :: String.t()
  @type address :: pos_integer()
  @type writable :: boolean()
  @type tensor :: Nx.Tensor.t()

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
end
