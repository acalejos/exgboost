defmodule EXGBoost.Plotting.Style do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      @type style :: Keyword.t()
      import EXGBoost.Plotting.Style
      Module.register_attribute(__MODULE__, :styles, accumulate: true)
    end
  end

  def deep_merge_kw(a, b, ignore_set \\ []) do
    Keyword.merge(a, b, fn
      _key, val_a, val_b when is_list(val_a) and is_list(val_b) ->
        deep_merge_kw(val_a, val_b)

      key, val_a, val_b ->
        if Keyword.has_key?(b, key) do
          if Keyword.has_key?(ignore_set, key) and Keyword.get(ignore_set, key) == val_b do
            val_a
          else
            val_b
          end
        else
          val_a
        end
    end)
  end

  def deep_merge_maps(b, a) do
    Map.merge(a, b, fn
      _key, val_a, val_b when is_map(val_a) and is_map(val_b) ->
        deep_merge_maps(val_a, val_b)

      key, val_a, val_b ->
        if Map.has_key?(b, key) do
          val_b
        else
          val_a
        end
    end)
  end

  defmacro style(style_name, do: body) do
    quote do
      @spec unquote(style_name)() :: style
      def unquote(style_name)(), do: unquote(body)
      Module.put_attribute(__MODULE__, :styles, {unquote(style_name), unquote(body)})
    end
  end
end
