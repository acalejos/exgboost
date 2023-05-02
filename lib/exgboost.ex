defmodule Exgboost do
  alias Exgboost.DMatrix
  import Exgboost.Internal

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
        ncol,
        opts \\ []
      )
      when is_integer(ncol) do
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
      Exgboost.NIF.dmatrix_create_from_csr(
        Jason.encode!(array_interface(indptr)),
        Jason.encode!(array_interface(indices)),
        Jason.encode!(array_interface(data)),
        ncol,
        Jason.encode!(config)
      )
      |> unwrap!()

    dmatrix(%DMatrix{ref: dmat}, opts)
  end
end
