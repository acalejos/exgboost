# Exgboost

Elixir bindings to the XGBoost C API (https://xgboost.readthedocs.io/en/stable/c.html) using Native Implemented Functions (NIFs)

# Requirements
* Make
* CMake
* If MacOS: `brew install libomp`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exgboost` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exgboost, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/exgboost>.

