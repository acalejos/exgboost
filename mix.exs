defmodule Exgboost.MixProject do
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
      name: "Exgboost",
      description:
        "Elixir bindings for the XGBoost library. `Exgboost` provides an implementation of XGBoost that works with
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
      {:nx, "~> 0.5"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.29.0", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Andres Alejos"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/acalejos/exgboost"}
    ]
  end

  defp docs do
    [
      main: "Exgboost"
    ]
  end
end
