defmodule EXGBoost.Application do
  @moduledoc false

  def start(_type, _args) do
    global_config = Application.get_all_env(:exgboost) |> Enum.into(%{})
    :ok = EXGBoost.set_config(global_config)
    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
