defmodule Exgboost do
  @moduledoc """
  Elixir bindings for the XGBoost library.

  Xtreme Gradient Boosting (XGBoost) is an optimized distributed gradient
  boosting library designed to be highly efficient, flexible and portable.
  It implements machine learning algorithms under the [Gradient Boosting](https://en.wikipedia.org/wiki/Gradient_boosting)
  framework. XGBoost provides a parallel tree boosting (also known as GBDT, GBM)
  that solve many data science problems in a fast and accurate way. The same code
  runs on major distributed environment (Hadoop, SGE, MPI) and can solve problems beyond
  billions of examples.

  ## Installation

  In order to use `Exgboost`, you will need Elixir installed. Then create an Elixir project via the `mix` build tool:

  ```
  $ mix new my_app
  ```

  Then you can add `Exgboost` as dependency in your `mix.exs`:

  ```elixir
  def deps do
  [
    {:exgboost, "~> 0.1.0"}
  ]
  end
  ```
  Then run `mix deps.get` to install it.

  And run `mix compile` to compile the library.

  ## Dependencies

  `Exgboost` depends on the [Nx](https://hexdocs.pm/nx/Nx.html) library for tensor creation and manipulation.

  ## Basic Usage

  iex> key = Nx.Random.key(42)
  iex> {X, _} = Nx.Random.normal(key, 0, 1, shape: {10, 5})
  iex> {y, _} = Nx.Random.normal(key, 0, 1, shape: {10})
  iex> model = Exgboost.train(X,y)
  iex> Exgboost.predict(model, X)

  ### Training

  ```elixir
  ```

  ### Prediction

  ```elixir
  ```

  """
  alias Exgboost.ArrayInterface
  alias Exgboost.Booster
  alias Exgboost.Internal
  alias Exgboost.DMatrix
  alias Exgboost.ProxyDMatrix
  alias Exgboost.Training

  @doc """
  Check the build information of the xgboost library.

  Returns a map containing information about the build.

  Example:
    iex> build = Exgboost.xgboost_build_info()
    iex> is_map(build)
    true
  """
  @spec xgboost_build_info() :: map()
  def xgboost_build_info,
    do: Exgboost.NIF.xgboost_build_info() |> Internal.unwrap!() |> Jason.decode!()

  @doc """
  Check the version of the xgboost library.

  Returns a 3-tuple in the form of `{major, minor, patch}`.

  Example:

      iex> v = Exgboost.xgboost_version()
      iex> is_tuple(v)

  """
  @spec xgboost_version() :: {integer(), integer(), integer()} | {:error, String.t()}
  def xgboost_version, do: Exgboost.NIF.xgboost_version() |> Internal.unwrap!()

  @doc """
  Set global configuration.

  Global configuration consists of a collection of parameters that can be
  applied in the global scope. See [Global Configuration](https://xgboost.readthedocs.io/en/latest/parameter.html#global-config)
  for the full list of parameters supported in the global configuration.

  """
  @spec set_config(map()) :: :ok | {:error, String.t()}
  def set_config(%{} = config) do
    Exgboost.NIF.set_global_config(Jason.encode!(config)) |> Internal.unwrap!()
  end

  @doc """
  Get current values of the global configuration.

  Global configuration consists of a collection of parameters that can be
  applied in the global scope. See [Global Configuration](https://xgboost.readthedocs.io/en/latest/parameter.html#global-config)
  for the full list of parameters supported in the global configuration.
  """
  @spec get_config() :: map()
  def get_config do
    Exgboost.NIF.get_global_config() |> Internal.unwrap!() |> Jason.decode!()
  end

  @doc """
  Train a new booster model given a data tensor and a label tensor

  ## Options
  * `:obj` - Specify the learning task and the corresponding learning objective. This function must accept two arguments: preds, dtrain. preds is an array of predicted real valued scores. dtrain is the training data set. This function returns gradient and second order gradient.
  * `:num_boost_rounds` - Number of boosting iterations.
  * `:evals` - A list of 3-Tuples `{X, y, label}` to use as a validation set for early-stopping.
  * `:early_stopping_rounds` - Activates early stopping. Validation error needs to decrease at least every `early_stopping_rounds` round(s) to continue training. Requires at least one item in `:evals`. If there's more than one, will use the last. If early stopping occurs, the model will have two additional fields:
        ``bst.best_score``, ``bst.best_iteration``.  If these values are `nil` then no early stopping occurred.
  * `:verbose_eval` - Requires at least one item in `evals`. If `verbose_eval` is true then the evaluation metric on the validation set is printed at each boosting stage. If verbose_eval is an
      integer then the evaluation metric on the validation set is printed at every given `verbose_eval` boosting stage. The last boosting stage / the boosting stage found by using `early_stopping_rounds`
      is also printed. Example: with `verbose_eval=4` and at least one item in evals, an evaluation metric is printed every 4 boosting stages, instead of every boosting stage.
  * `:learning_rates` - Either an arity 1 function that accept an integer parameter epoch and returns the corresponding learning rate or a list with the same length as num_boost_rounds.
  * `:callbacks` - List of callback functions that are applied at end of each iteration. It is possible to use predefined callbacks by using `Exgboost.Callback` module.
      Callbacks should be in the form of a keyword list where the only valid keys are `:before_training`, `:after_training`, `:before_iteration`, and `:after_iteration`.
      The value of each key should be a list of functions that accepts a booster and an iteration and returns a booster. The function will be called at the appropriate time with the booster and the iteration
      as the arguments. The function should return the booster. If the function returns a booster with a different memory address, the original booster will be replaced with the new booster.
      If the function returns the original booster, the original booster will be used. If the function returns a booster with the same memory address but different contents, the behavior is undefined.

  ## Example

  """
  @spec train(Nx.Tensor.t(), Nx.Tensor.t(), Keyword.t()) :: Exgboost.Booster.t()
  def train(%Nx.Tensor{} = x, %Nx.Tensor{} = y, opts \\ []) do
    {dmat_opts, opts} = Keyword.split(opts, Internal.dmatrix_feature_opts())
    dmat = Exgboost.DMatrix.from_tensor(x, y, [format: :dense] ++ dmat_opts)
    Training.train(dmat, opts)
  end

  @doc """
  Predict with a booster model against a tensor

  The full model will be used unless `iteration_range` is specified,
  meaning user have to either slice the model or use the `best_iteration`
  attribute to get prediction from best model returned from early stopping.

  ## Options

  * `:output_margin` - Whether to output the raw untransformed margin value.

  * `:pred_leaf ` - When this option is on, the output will be a matrix of (nsample,
      ntrees) with each record indicating the predicted leaf index of
      each sample in each tree.  Note that the leaf index of a tree is
      unique per tree, so you may find leaf 1 in both tree 1 and tree 0.

  * `:pred_contribs` - When this is True the output will be a matrix of size (nsample,
      nfeats + 1) with each record indicating the feature contributions
      (SHAP values) for that prediction. The sum of all feature
      contributions is equal to the raw untransformed margin value of the
      prediction. Note the final column is the bias term.

  * `:approx_contribs` - Approximate the contributions of each feature.  Used when ``pred_contribs`` or
      ``pred_interactions`` is set to True.  Changing the default of this parameter
      (False) is not recommended.

  * `:pred_interactions` - When this is True the output will be a matrix of size (nsample,
      nfeats + 1, nfeats + 1) indicating the SHAP interaction values for
      each pair of features. The sum of each row (or column) of the
      interaction values equals the corresponding SHAP value (from
      pred_contribs), and the sum of the entire matrix equals the raw
      untransformed margin value of the prediction. Note the last row and
      column correspond to the bias term.

  * `:validate_features` - When this is True, validate that the Booster's and data's
      feature_names are identical.  Otherwise, it is assumed that the
      feature_names are the same.

  * `:training` - Whether the prediction value is used for training.  This can effect `dart`
      booster, which performs dropouts during training iterations but use all trees
      for inference. If you want to obtain result with dropouts, set this parameter
      to `True`.  Also, the parameter is set to true when obtaining prediction for
      custom objective function.

  * `:iteration_range` - Specifies which layer of trees are used in prediction.  For example, if a
      random forest is trained with 100 rounds.  Specifying `iteration_range=(10,
      20)`, then only the forests built during [10, 20) (half open set) rounds are
      used in this prediction.

  * `:strict_shape` - When set to True, output shape is invariant to whether classification is used.
      For both value and margin prediction, the output shape is (n_samples,
      n_groups), n_groups == 1 when multi-class is not used.  Default to False, in
      which case the output shape can be (n_samples, ) if multi-class is not used.

  Returns an Nx.Tensor containing the predictions.
  """
  def predict(%Booster{} = bst, %Nx.Tensor{} = x, opts \\ []) do
    {dmat_opts, opts} = Keyword.split(opts, Internal.dmatrix_feature_opts())
    dmat = Exgboost.DMatrix.from_tensor(x, [format: :dense] ++ dmat_opts)
    Booster.predict(bst, dmat, opts)
  end

  def inplace_predict(%Booster{} = boostr, data, opts \\ []) do
    opts =
      Keyword.validate!(opts,
        iteration_range: {0, 0},
        predict_type: "value",
        missing: Nx.Constants.nan(),
        validate_features: true,
        base_margin: nil,
        strict_shape: false
      )

    base_margin = Keyword.fetch!(opts, :base_margin)
    {iteration_range_left, iteration_range_right} = Keyword.fetch!(opts, :iteration_range)

    params = %{
      type: if(Keyword.fetch!(opts, :predict_type) == "margin", do: 1, else: 0),
      training: false,
      iteration_begin: iteration_range_left,
      iteration_end: iteration_range_right,
      missing: Keyword.fetch!(opts, :missing),
      strict_shape: Keyword.fetch!(opts, :strict_shape),
      cache_id: 0
    }

    proxy =
      if not is_nil(base_margin) do
        prox = ProxyDMatrix.proxy_dmatrix()
        prox = DMatrix.set_params(prox, base_margin: base_margin)
        prox.ref
      else
        nil
      end

    # if validate_features do
    # if not hasattr(data, "shape") do
    #     raise TypeError(
    #         "`shape` attribute is required when `validate_features` is True."
    #     )
    # end
    # if len(data.shape) != 1 and self.num_features() != data.shape[1]:
    #     raise ValueError(
    #         f"Feature shape mismatch, expected: {self.num_features()}, "
    #         f"got {data.shape[1]}"
    #     )
    # end

    case data do
      %Nx.Tensor{} ->
        data_interface = ArrayInterface.array_interface(data) |> Jason.encode!()

        {shape, preds} =
          Exgboost.NIF.booster_predict_from_dense(
            boostr.ref,
            data_interface,
            Jason.encode!(params),
            proxy
          )
          |> Internal.unwrap!()

        Nx.tensor(preds) |> Nx.reshape(shape)

      {%Nx.Tensor{} = indptr, %Nx.Tensor{} = indices, %Nx.Tensor{} = values, ncol} ->
        indptr_interface = ArrayInterface.array_interface(indptr) |> Jason.encode!()
        indices_interface = ArrayInterface.array_interface(indices) |> Jason.encode!()
        values_interface = ArrayInterface.array_interface(values) |> Jason.encode!()

        {shape, preds} =
          Exgboost.NIF.booster_predict_from_csr(
            boostr.ref,
            indptr_interface,
            indices_interface,
            values_interface,
            ncol,
            Jason.encode!(params),
            proxy
          )
          |> Internal.unwrap!()

        Nx.tensor(preds) |> Nx.reshape(shape)
    end
  end
end
