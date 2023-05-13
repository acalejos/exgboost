defmodule Exgboost.Training.Callback do
  @enforce_keys [:event, :fun]
  defstruct [:event, :fun, :name, :init_state]

  def new(event, fun) do
    new(event, fun, nil, %{})
  end

  def new(event, fun, name, %{} = init_state)
      when event in [:before_training, :after_training, :before_iteration, :after_iteration] and
             is_atom(name) do
    %__MODULE__{event: event, fun: fun, name: name, init_state: init_state}
  end
end
