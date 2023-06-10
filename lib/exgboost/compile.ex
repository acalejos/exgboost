defimpl DecisionTree, for: EXGBoost.Booster do
  @spec trees(data :: any) :: [Tree.t()]
  def trees(data) do
    model = EXGBoost.
  end

  @spec num_classes(data :: any) :: pos_integer()
  def num_classes(data)

  @spec num_features(data :: any) :: pos_integer()
  def num_features(data)

  @spec output_type(data :: any) :: :classification | :regression
  def output_type(data)

  @spec condition(data :: any) :: :gt | :lt | :ge | :le
  def condition(data)
end
