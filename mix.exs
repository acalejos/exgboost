defmodule EXGBoost.MixProject do
  use Mix.Project
  @version "0.4.0"

  def project do
    [
      app: :exgboost,
      version: @version,
      make_precompiler: {:nif, CCPrecompiler},
      make_precompiler_url:
        "https://github.com/acalejos/exgboost/releases/download/v#{@version}/@{artefact_filename}",
      make_precompiler_priv_paths: ["libexgboost.*", "lib"],
      # NIF Versions correspond to OTP Releases
      # https://github.com/erlang/otp/blob/d3aa6c044c3927f011fb76ac087d5ce0e814954c/erts/emulator/beam/erl_nif.h#L57
      make_precompiler_nif_versions: [
        versions: ["2.15", "2.16", "2.17"]
      ],
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs
      ],
      before_closing_body_tag: &before_closing_body_tag/1,
      name: "EXGBoost",
      description:
        "Elixir bindings for the XGBoost library. `EXGBoost` provides an implementation of XGBoost that works with
      [Nx](https://hexdocs.pm/nx/Nx.html) tensors."
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
      {:elixir_make, "~> 0.4", runtime: false},
      {:nimble_options, "~> 1.0"},
      {:nx, "~> 0.5"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.29.0", only: :docs},
      {:cc_precompiler, "~> 0.1.0", runtime: false},
      {:exterval, "0.1.0"},
      {:exonerate, "~> 1.1", runtime: false},
      {:httpoison, "~> 2.0", runtime: false},
      {:vega_lite, "~> 0.1"},
      {:kino, "~> 0.11"}
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
        "LICENSE",
        ".formatter.exs",
        "checksum.exs"
      ]
    ]
  end

  defp docs do
    [
      main: "EXGBoost",
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
    """
  end

  defp before_closing_body_tag(_), do: ""
end
