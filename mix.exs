defmodule EXGBoost.MixProject do
  use Mix.Project

  def project do
    [
      app: :exgboost,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "EXGBoost",
      description:
        "Elixir bindings for the XGBoost library. `EXGBoost` provides an implementation of XGBoost that works with
      [Nx](https://hexdocs.pm/nx/Nx.html) tensors."
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:nimble_options, "~> 0.3.0"},
      {:nx, "~> 0.5"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.29.0", only: :docs}
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
        ".formatter.exs"
      ]
    ]
  end

  defp docs do
    [
      main: "EXGBoost"
    ]
  end
end
