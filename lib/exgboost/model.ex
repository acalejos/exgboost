defprotocol Model do
  def set_param(data, opts \\ [])

  def set_attr(data, opts \\ [])

  def attr(data, opts \\ [])

  def num_boosted_rounds(data, opts \\ [])

  def best_iteration(data, opts \\ [])

  def best_score(data, opts \\ [])

  @spec eval(data :: any, opts :: Keyword.t()) :: any
  def eval(data, opts \\ [])

  def eval_set(data, opts \\ [])

  def update(data, opts \\ [])

  def predict(data, opts \\ [])

  def save(data, opts \\ [])

  def load(data, opts \\ [])

  def dump_model(data, opts \\ [])
end
