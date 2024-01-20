defmodule EXGBoost.Training.State do
  @moduledoc false
  @enforce_keys [:booster]
  defstruct [
    :booster,
    iteration: 0,
    max_iteration: -1,
    meta_vars: %{},
    metrics: %{},
    status: :cont
  ]

  def validate!(%__MODULE__{} = state) do
    unless state.status in [:cont, :halt] do
      raise ArgumentError,
            "`status` must be `:cont` or `:halt`, found: `#{inspect(state.status)}`."
    end

    state
  end
end
