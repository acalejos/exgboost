defmodule Exgboost.DMatrix do
  @enforce_keys [:ref]
  defstruct [:ref]

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
