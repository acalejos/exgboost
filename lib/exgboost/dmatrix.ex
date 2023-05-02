defmodule Exgboost.DMatrix do
  @enforce_keys [:ref]
  defstruct [:ref]

  # TODO: Define access for the following: rows, cols, non_missing, weight, label, base_margin, group, label_upper_bound, label_lower_bound, feature_weights
  @behaviour Access

  def rows(%Exgboost.DMatrix{ref: ref}) do
    Exgboost.NIF.dmatrix_num_row(ref)
  end

  def cols(%Exgboost.DMatrix{ref: ref}) do
    Exgboost.NIF.dmatrix_num_col(ref)
  end

  def non_missing(%Exgboost.DMatrix{ref: ref}) do
    Exgboost.NIF.dmatrix_num_non_missing(ref)
  end
end
