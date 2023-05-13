defmodule Exgboost.Training.State do
  @enforce_keys [:booster]
  defstruct [
    :booster,
    meta_vars: %{},
    iteration: 0,
    max_iteration: -1,
    metrics: %{}
  ]
end
