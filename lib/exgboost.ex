defmodule Exgboost do
  alias Exgboost.DMatrix
  import Exgboost.Internal

  # TODO: Pull "missing" key out of config for construction to mirror Python API
  def dmatrix(value, opts \\ [])

  def dmatrix(%Nx.Tensor{} = tensor, opts) do
    opts =
      Keyword.validate!(opts, [
        :label,
        :weight,
        :base_margin,
        :group,
        :label_upper_bound,
        :label_lower_bound,
        :feature_weights,
        config: %{missing: -1.0}
      ])

    {config, opts} = Keyword.pop!(opts, :config)

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(
        Jason.encode!(array_interface(tensor)),
        Jason.encode!(config)
      )
      |> unwrap!()

    dmatrix(%DMatrix{ref: dmat}, opts)
  end

  def dmatrix(%DMatrix{} = dmat, opts) do
    opts =
      Keyword.validate!(opts, [
        :label,
        :weight,
        :base_margin,
        :group,
        :label_upper_bound,
        :label_lower_bound,
        :feature_weights
      ])

    Enum.each(opts, fn {key, value} ->
      data_interface = array_interface(value) |> Jason.encode!()
      Exgboost.NIF.dmatrix_set_info_from_interface(dmat.ref, Atom.to_string(key), data_interface)
    end)

    dmat
  end

  def dmatrix(
        %Nx.Tensor{} = indptr,
        %Nx.Tensor{} = indices,
        %Nx.Tensor{} = data,
        n,
        opts \\ []
      )
      when is_integer(n) do
    opts =
      Keyword.validate!(opts, [
        :label,
        :weight,
        :base_margin,
        :group,
        :label_upper_bound,
        :label_lower_bound,
        :feature_weights,
        format: :csr,
        config: %{missing: -1.0}
      ])

    {config, opts} = Keyword.pop!(opts, :config)
    {format, opts} = Keyword.pop!(opts, :format)

    dmat =
      Exgboost.NIF.dmatrix_create_from_sparse(
        Jason.encode!(array_interface(indptr)),
        Jason.encode!(array_interface(indices)),
        Jason.encode!(array_interface(data)),
        n,
        Jason.encode!(config),
        Atom.to_string(format)
      )
      |> unwrap!()

    dmatrix(%DMatrix{ref: dmat}, opts)
  end
end
