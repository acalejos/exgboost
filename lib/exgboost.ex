defmodule Exgboost do
  import Exgboost.Internal

  def dmatrix(%Nx.Tensor{} = tensor, opts \\ []) do
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

    IO.inspect(opts)

    {config, opts} = Keyword.pop!(opts, :config)

    array_interface = array_interface(tensor)

    dmat =
      Exgboost.NIF.dmatrix_create_from_dense(
        Jason.encode!(array_interface),
        Jason.encode!(config)
      )
      |> unwrap!()

    Enum.each(opts, fn {key, value} ->
      data_interface = array_interface(value) |> Jason.encode!()
      Exgboost.NIF.dmatrix_set_info_from_interface(dmat, Atom.to_string(key), data_interface)
    end)

    %Exgboost.DMatrix{ref: dmat}
  end
end
