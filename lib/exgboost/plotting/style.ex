defmodule EXGBoost.Plotting.Style do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      import EXGBoost.Plotting.Style
      Module.register_attribute(__MODULE__, :styles, accumulate: true)
    end
  end

  def deep_merge_kw(a, b) do
    Keyword.merge(a, b, fn
      _key, val_a, val_b when is_list(val_a) and is_list(val_b) ->
        deep_merge_kw(val_a, val_b)

      key, val_a, val_b ->
        if Keyword.has_key?(b, key) do
          val_b
        else
          val_a
        end
    end)
  end

  defmacro style(style_name, do: body) do
    quote do
      def unquote(style_name)(), do: unquote(body)
      Module.put_attribute(__MODULE__, :styles, {unquote(style_name), unquote(body)})
    end
  end
end
