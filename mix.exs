defmodule Exgboost.MixProject do
  use Mix.Project

  def project do
    [
      app: :exgboost,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:xgboost,
       git: "https://github.com/dmlc/xgboost.git",
       submodules: true,
       compile: "mkdir build && cmake -B build && make -C build install"}
    ]
  end
end

# For CUDA toolkit >= 11.4, `BUILD_WITH_CUDA_CUB` is required.
# cmake .. -DUSE_CUDA=ON -DBUILD_WITH_CUDA_CUB=ON
