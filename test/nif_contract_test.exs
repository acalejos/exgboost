defmodule NifContractTest do
  use ExUnit.Case, async: true

  @nif_c_file Path.expand("../c/exgboost/src/exgboost.c", __DIR__)

  test "Elixir NIF stubs match C registered NIF functions" do
    c_source = File.read!(@nif_c_file)

    c_exports =
      Regex.scan(~r/\{"([a-z0-9_]+)",\s*(\d+),/i, c_source)
      |> Enum.map(fn [_, name, arity] -> {String.to_atom(name), String.to_integer(arity)} end)
      |> MapSet.new()

    elixir_exports =
      EXGBoost.NIF.__info__(:functions)
      |> Enum.reject(fn {name, _arity} -> name in [:module_info, :__info__, :on_load] end)
      |> MapSet.new()

    assert c_exports == elixir_exports,
           "NIF API mismatch. Missing in C: #{inspect(MapSet.difference(elixir_exports, c_exports))}. " <>
             "Missing in Elixir: #{inspect(MapSet.difference(c_exports, elixir_exports))}"
  end
end
