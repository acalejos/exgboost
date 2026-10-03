# Compile only on the current architecture. Fetch advertises every released target.
# This prevents a native XGBoost build from being mislabeled as a cross-build.
defmodule EXGBoost.Precompiler do
  @targets ~w(x86_64-linux-gnu aarch64-linux-gnu x86_64-apple-darwin aarch64-apple-darwin)
  def all_supported_targets(:fetch), do: @targets

  def all_supported_targets(:compile) do
    {:ok, target} = current_target()
    if target in @targets, do: [target], else: []
  end

  def current_target, do: CCPrecompiler.current_target(:os.type())
  def build_native(args), do: CCPrecompiler.build_native(args)

  def precompile(args, target) do
    case current_target() do
      {:ok, ^target} -> CCPrecompiler.precompile(args, target)
      _ -> {:error, "EXGBoost requires a native runner for #{target}"}
    end
  end
end

defmodule EXGBoost.MixProject do
  use Mix.Project

  @version "0.6.0"

  def project do
    [
      app: :exgboost,
      version: @version,
      make_precompiler: {:nif, EXGBoost.Precompiler},
      make_precompiler_url:
        "https://github.com/acalejos/exgboost/releases/download/v#{@version}/@{artefact_filename}",
      make_precompiler_priv_paths: ["libexgboost.*", "lib", "licenses"],
      # OTP 26's NIF ABI loads on later OTP releases; build once per native target.
      make_precompiler_nif_versions: [versions: ["2.17"]],
      cc_precompiler: [
        only_listed_targets: true,
        compilers: %{
          {:unix, :linux} => %{
            "x86_64-linux-gnu" => {"cc", "g++"},
            "aarch64-linux-gnu" => {"cc", "g++"}
          },
          {:unix, :darwin} => %{
            "x86_64-apple-darwin" => {"cc", "c++"},
            "aarch64-apple-darwin" => {"cc", "c++"}
          }
        }
      ],
      elixir: "~> 1.17",
      make_force_build: System.get_env("EXGBOOST_BUILD") == "true",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps(),
      name: "EXGBoost",
      source_url: "https://github.com/acalejos/exgboost",
      homepage_url: "https://github.com/acalejos/exgboost",
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      aliases: [quality: ["format --check-formatted", "compile --warnings-as-errors", "test"]],
      description:
        "Elixir bindings for the XGBoost library. `EXGBoost` provides an implementation of XGBoost that works with
      [Nx](https://hexdocs.pm/nx/Nx.html) tensors."
    ]
  end

  def cli do
    [
      preferred_envs: [
        docs: :docs,
        "hex.publish": :docs,
        quality: :test,
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EXGBoost.Application, []}
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.9", runtime: false},
      {:castore, "~> 1.0", only: :test, runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:nimble_options, "~> 1.0"},
      {:nx, "~> 1.0"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.40", only: :docs, runtime: false},
      {:cc_precompiler, "~> 0.1.11", runtime: false},
      {:exterval, "~> 0.2.0"},
      {:ex_json_schema, "~> 0.11.4"},
      {:vega_lite, "~> 0.1"},
      {:vega_lite_convert, "~> 1.0.1", only: [:dev, :docs], optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Andres Alejos"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/acalejos/exgboost"},
      files: [
        "lib",
        "mix.exs",
        "c",
        "Makefile",
        "README.md",
        "CHANGELOG.md",
        "RELEASING.md",
        "scripts",
        "LICENSE",
        ".formatter.exs",
        "checksum.exs"
      ]
    ]
  end

  defp docs do
    [
      main: "EXGBoost",
      extras: [
        "RELEASING.md",
        "CONTRIBUTING.md",
        "CHANGELOG.md",
        "notebooks/iris_classification.livemd",
        "notebooks/quantile_prediction_interval.livemd",
        "notebooks/plotting.livemd"
      ],
      groups_for_extras: [
        Notebooks: Path.wildcard("notebooks/*.livemd")
      ],
      groups_for_docs: [
        "System / Native Config": &(&1[:type] == :system),
        "Training & Prediction": &(&1[:type] == :train_pred),
        Serialization: &(&1[:type] == :serialization),
        Plotting: &(&1[:type] == :plotting)
      ],
      groups_for_modules: [
        Plotting: [EXGBoost.Plotting, EXGBoost.Plotting.Styles],
        Training: [
          EXGBoost.Training,
          EXGBoost.Training.Callback,
          EXGBoost.Booster,
          EXGBoost.Parameters
        ]
      ],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <!-- Render math with KaTeX -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/katex.min.css" integrity="sha384-t5CR+zwDAROtph0PXGte6ia8heboACF9R5l/DiY+WZ3P2lxNgvJkQk5n7GPvLMYw" crossorigin="anonymous">
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/katex.min.js" integrity="sha384-FaFLTlohFghEIZkw6VGwmf9ISTubWAVYW8tG8+w2LAIftJEULZABrF9PPFv+tVkH" crossorigin="anonymous"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/contrib/auto-render.min.js" integrity="sha384-bHBqxz8fokvgoJ/sc17HODNxa42TlaEhB+w8ZJXTc2nZf1VgEaFZeZvT4Mznfz0v" crossorigin="anonymous"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function() {
        renderMathInElement(document.body, {
          delimiters: [
            { left: "$$", right: "$$", display: true },
            { left: "$", right: "$", display: false },
          ]
        });
      });
    </script>

    <!-- Render diagrams with Mermaid -->
    <script src="https://cdn.jsdelivr.net/npm/mermaid@8.13.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
            graphEl.innerHTML = svgSource;
            bindListeners && bindListeners(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>

    <!-- Render Vega-Lite charts -->
      <script src="https://cdn.jsdelivr.net/npm/vega@5.20.2"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-lite@5.1.1"></script>
      <script src="https://cdn.jsdelivr.net/npm/vega-embed@6.18.2"></script>
      <style>
        .vega-container {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); /* Create as many columns as can fit items of at least 200px */
          column-gap: 200px; /* Add a gap between the grid items */
        }

        .vega-item {
          width: 100%; /* Make the items take up the full width of the grid cell */
        }
      </style>
      <script>
        document.addEventListener("DOMContentLoaded", function () {
          for (const codeEl of document.querySelectorAll("pre code.vega-lite")) {
            try {
              const preEl = codeEl.parentElement;
              const spec = JSON.parse(codeEl.textContent);
              const plotEl = document.createElement("div");
              preEl.insertAdjacentElement("afterend", plotEl);
              vegaEmbed(plotEl, spec);
              preEl.remove();
            } catch (error) {
              console.log("Failed to render Vega-Lite plot: " + error)
            }
          }
        });
      </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
