defmodule Exgboost.NIF do
  @on_load :on_load

  def on_load do
    IO.puts(:code.priv_dir(:exgboost))
    path = :filename.join([:code.priv_dir(:exgboost), "libexgboost"])
    :erlang.load_nif(path, 0)
  end

  def fast_compare(_a, _b), do: :erlang.nif_error(:not_implemented)
end
