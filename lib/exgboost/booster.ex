defmodule Exgboost.Booster do
  @enforce_keys [:ref]
  defstruct [:ref]

  @behaviour Access
  @impl Access
  def fetch(booster, "feature_names"),
    do: Exgboost.NIF.booster_get_str_feature_info(booster.ref, "feature_name")

  def fetch(booster, "feature_types"),
    do: Exgboost.NIF.booster_get_str_feature_info(booster.ref, "feature_type")

  def fetch(booster, "num_features"),
    do: Exgboost.NIF.booster_get_num_feature(booster.ref)

  def(fetch(booster, "attrs"), do: Exgboost.NIF.booster_get_attr_names(booster.ref))

  def fetch(booster, "boosted_rounds") do
    Exgboost.NIF.booster_boosted_rounds(booster.ref)
  end

  def fetch(booster, attr) do
    attrs = fetch(booster, "attrs")

    if Enum.member?(attrs, attr) do
      Exgboost.NIF.booster_get_attr(booster.ref, attr)
    else
      :error
    end
  end
end
