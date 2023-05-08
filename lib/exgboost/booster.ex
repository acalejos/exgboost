defmodule Exgboost.Booster do
  alias __MODULE__
  alias Exgboost.DMatrix
  alias Exgboost.Internal
  @enforce_keys [:ref]
  defstruct [:ref]

  def booster(dmats, opts \\ [])

  def booster([%DMatrix{} | _] = dmats, opts) when is_list(dmats) do
    refs = Enum.map(dmats, & &1.ref)
    booster_ref = Exgboost.NIF.booster_create(refs) |> Internal.unwrap!()
    set_params(%Booster{ref: booster_ref}, opts)
  end

  def booster(%DMatrix{} = dmat, opts) do
    booster([dmat], opts)
  end

  def set_params(booster, opts \\ []) do
    # opts = Keyword.validate!(opts, [:params, :cache])
    # TODO: List of params here: https://xgboost.readthedocs.io/en/latest/parameter.html
    # Eventually we should validate, but there's so many, for now we will let XGBoost fail
    # on invalid params
    for {key, value} <- opts do
      Exgboost.NIF.booster_set_param(booster.ref, Atom.to_string(key), value)
    end

    booster
  end

  def get_feature_names(booster),
    do:
      Exgboost.NIF.booster_get_str_feature_info(booster.ref, "feature_name") |> Internal.unwrap!()

  def get_feature_types(booster),
    do:
      Exgboost.NIF.booster_get_str_feature_info(booster.ref, "feature_type") |> Internal.unwrap!()

  def get_num_features(booster),
    do: Exgboost.NIF.booster_get_num_feature(booster.ref) |> Internal.unwrap!()

  def get_attrs(booster),
    do: Exgboost.NIF.booster_get_attr_names(booster.ref) |> Internal.unwrap!()

  def get_boosted_rounds(booster) do
    Exgboost.NIF.booster_boosted_rounds(booster.ref) |> Internal.unwrap!()
  end

  def get_attr(booster, attr) do
    attrs = get_attrs(booster)

    if Enum.member?(attrs, attr) do
      Exgboost.NIF.booster_get_attr(booster.ref, attr) |> Internal.unwrap!()
    else
      :error
    end
  end

  @doc """
  Slice a model using boosting index. The slice m:n indicates taking all
  trees that were fit during the boosting rounds m, (m+1), (m+2), …, (n-1).
  """
  def slice(boostr, begin_layer, end_layer, step) do
    Exgboost.NIF.booster_slice(boostr.ref, begin_layer, end_layer, step) |> Internal.unwrap!()
  end
end
