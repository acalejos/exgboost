defmodule EXGBoost.Plotting.Styles do
  @bst File.cwd!() |> Path.join("test/data/model.json") |> EXGBoost.read_model()

  @moduledoc """
  <div class="vega-container">
  #{Enum.map(EXGBoost.Plotting.get_styles(), fn {name, _style} -> """
    <div class="vega-item">
      <h2>#{name}</h2>
      <pre>
        <code class="vega-lite">
        #{EXGBoost.Plotting.to_vega(@bst, style: name, height: 200, width: 300).spec |> Jason.encode!()}
        </code>
      </pre>
    </div>
    """ end) |> Enum.join("\n\n")}
  </div>
  """
end
