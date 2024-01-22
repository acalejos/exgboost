defmodule EXGBoost.Plotting.Style do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      import EXGBoost.Plotting.Style
      Module.register_attribute(__MODULE__, :styles, accumulate: true)
    end
  end

  defmacro style(style_name, do: body) do
    quote do
      def unquote(style_name)(), do: unquote(body)
      Module.put_attribute(__MODULE__, :styles, {unquote(style_name), unquote(body)})
    end
  end
end
