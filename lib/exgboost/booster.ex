defmodule Exgboost.Booster do
  @enforce_keys [:ref]
  defstruct [:ref, params: %{}]
end
