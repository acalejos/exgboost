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
        :feature_name,
        :feature_type,
        format: :dense,
        missing: -1.0,
        nthread: 0
      ])

    {config_opts, format_opts, meta_opts, str_opts} =
      DMatrix.get_args_groups(opts, [:config, :format, :meta, :str])

    config = Enum.into(config_opts, %{}, fn {key, value} -> {Atom.to_string(key), value} end)
    format = Keyword.fetch!(format_opts, :format)

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(
        Jason.encode!(array_interface(tensor)),
        Jason.encode!(config)
      )
      |> unwrap!()

    dmatrix(%DMatrix{ref: dmat, format: format}, Keyword.merge(meta_opts, str_opts))
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

    {meta_opts, str_opts} = DMatrix.get_args_groups(opts, [:meta, :str])

    Enum.each(meta_opts, fn {key, value} ->
      data_interface = array_interface(value) |> Jason.encode!()
      Exgboost.NIF.dmatrix_set_info_from_interface(dmat.ref, Atom.to_string(key), data_interface)
    end)

    Enum.each(str_opts, fn {key, value} ->
      Exgboost.NIF.dmatrix_set_str_feature_info(dmat.ref, Atom.to_string(key), value)
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
      when is_integer(n) and n > 0 do
    opts =
      Keyword.validate!(opts, [
        :label,
        :weight,
        :base_margin,
        :group,
        :label_upper_bound,
        :label_lower_bound,
        :feature_weights,
        :feature_name,
        :feature_type,
        format: :csr,
        missing: -1.0,
        nthread: 0
      ])

    {config_opts, format_opts, meta_opts, str_opts} =
      DMatrix.get_args_groups(opts, [:config, :format, :meta, :str])

    config = Enum.into(config_opts, %{}, fn {key, value} -> {Atom.to_string(key), value} end)
    format = Keyword.fetch!(format_opts, :format)

    if format not in [:csr, :csc] do
      raise ArgumentError, "Sparse format must be :csr or :csc"
    end

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

    dmatrix(%DMatrix{ref: dmat, format: format}, Keyword.merge(meta_opts, str_opts))
  end
end
