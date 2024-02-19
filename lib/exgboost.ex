defmodule EXGBoost do
  @moduledoc """
  #{File.cwd!() |> Path.join("README.md") |> File.read!() |> then(&Regex.run(~r/.*<!-- BEGIN MODULEDOC -->(?P<body>.*)<!-- END MODULEDOC -->.*/s, &1, capture: :all_but_first)) |> hd()}
  """

  alias EXGBoost.ArrayInterface
  alias EXGBoost.Booster
  alias EXGBoost.Internal
  alias EXGBoost.DMatrix
  alias EXGBoost.ProxyDMatrix
  alias EXGBoost.Training
  alias EXGBoost.Plotting

  @doc """
  Check the build information of the xgboost library.

  Returns a map containing information about the build.
  """
  @spec xgboost_build_info() :: map()
  @doc type: :system
  def xgboost_build_info,
    do: EXGBoost.NIF.xgboost_build_info() |> Internal.unwrap!() |> Jason.decode!()

  @doc """
  Check the version of the xgboost library.

  Returns a 3-tuple in the form of `{major, minor, patch}`.
  """
  @spec xgboost_version() :: {integer(), integer(), integer()} | {:error, String.t()}
  @doc type: :system
  def xgboost_version, do: EXGBoost.NIF.xgboost_version() |> Internal.unwrap!()

  @doc """
  Set global configuration.

  Global configuration consists of a collection of parameters that can be
  applied in the global scope. See `Global Parameters` in `EXGBoost.Parameters`
  for the full list of parameters supported in the global configuration.
  """
  @spec set_config(map()) :: :ok | {:error, String.t()}
  @doc type: :system
  def set_config(%{} = config) do
    config = EXGBoost.Parameters.validate_global!(config)
    EXGBoost.NIF.set_global_config(Jason.encode!(config)) |> Internal.unwrap!()
  end

  @doc """
  Get current values of the global configuration.

  Global configuration consists of a collection of parameters that can be
  applied in the global scope. See `Global Parameters` in `EXGBoost.Parameters`
  for the full list of parameters supported in the global configuration.
  """
  @spec get_config() :: map()
  @doc type: :system
  def get_config do
    EXGBoost.NIF.get_global_config() |> Internal.unwrap!() |> Jason.decode!()
  end

  @doc """
  Train a new booster model given a data tensor and a label tensor.

  ## Options

  * `:obj` - Specify the learning task and the corresponding learning objective.
    This function must accept two arguments: preds, dtrain. preds is an array of
    predicted real valued scores. dtrain is the training data set. This function
    returns gradient and second order gradient.

  * `:num_boost_rounds` - Number of boosting iterations.

  * `:evals` - A list of 3-Tuples `{x, y, label}` to use as a validation set for
    early-stopping.

  * `:early_stopping_rounds` - Activates early stopping. Target metric needs to
    increase/decrease (depending on metric) at least every `early_stopping_rounds`
    round(s) to continue training. Requires at least one item in `:evals`. If there's
    more than one, will use the last eval set. If there’s more than one metric in the
    `eval_metric` parameter given in the booster's params, the last metric will be
    used for early stopping. If early stopping occurs, the model will have two additional fields:


      - `bst.best_score`
      - `bst.best_iteration`.

    If these values are `nil` then no early stopping occurred.

  * `:verbose_eval` - Requires at least one item in `evals`. If `verbose_eval` is true then the evaluation metric on the validation set is printed at each boosting stage. If verbose_eval is an
      integer then the evaluation metric on the validation set is printed at every given `verbose_eval` boosting stage. The last boosting stage / the boosting stage found by using `early_stopping_rounds`
      is also printed. Example: with `verbose_eval=4` and at least one item in evals, an evaluation metric is printed every 4 boosting stages, instead of every boosting stage.

  * `:learning_rates` - Either an arity 1 function that accept an integer parameter epoch and returns the corresponding learning rate or a list with the same length as num_boost_rounds.

  * `:callbacks` - List of `EXGBoost.Training.Callback` that are called during a given event. It is possible to use predefined callbacks by using `EXGBoost.Training.Callback` module.
      Callbacks should be in the form of a keyword list where the only valid keys are `:before_training`, `:after_training`, `:before_iteration`, and `:after_iteration`.
      The value of each key should be a list of functions that accepts a booster and an iteration and returns a booster. The function will be called at the appropriate time with the booster and the iteration
      as the arguments. The function should return the booster. If the function returns a booster with a different memory address, the original booster will be replaced with the new booster.
      If the function returns the original booster, the original booster will be used. If the function returns a booster with the same memory address but different contents, the behavior is undefined.


  * `opts` - Refer to `EXGBoost.Parameters` for the full list of options.
  """
  @spec train(Nx.Tensor.t(), Nx.Tensor.t(), Keyword.t()) :: EXGBoost.Booster.t()
  @doc type: :train_pred
  def train(x, y, opts \\ []) do
    x = Nx.concatenate(x)
    y = Nx.concatenate(y)
    dmat_opts = Keyword.take(opts, Internal.dmatrix_feature_opts())
    dmat = DMatrix.from_tensor(x, y, Keyword.put_new(dmat_opts, :format, :dense))
    Training.train(dmat, opts)
  end

  @doc """
  Predict with a booster model against a tensor.

  The full model will be used unless `iteration_range` is specified,
  meaning user have to either slice the model or use the `best_iteration`
  attribute to get prediction from best model returned from early stopping.

  ## Options

  * `:output_margin` - Whether to output the raw untransformed margin value.

  * `:pred_leaf ` - When this option is on, the output will be an `Nx.Tensor` of
      shape {nsamples, ntrees}, where each row indicates the predicted leaf
      index of each sample in each tree. Note that the leaf index of a tree is
      unique per tree, but not globally, so you may find leaf 1 in both tree 1 and tree 0.

  * `:pred_contribs` - When this is `true` the output will be a matrix of size `{nsample,
      nfeats + 1}` with each record indicating the feature contributions
      (SHAP values) for that prediction. The sum of all feature
      contributions is equal to the raw untransformed margin value of the
      prediction. Note the final column is the bias term.

  * `:approx_contribs` - Approximate the contributions of each feature.  Used when `pred_contribs` or
      `pred_interactions` is set to `true`.  Changing the default of this parameter
      (false) is not recommended.

  * `:pred_interactions` - When this is `true` the output will be an `Nx.Tensor` of shape
      {nsamples, nfeats + 1} indicating the SHAP interaction values for
      each pair of features. The sum of each row (or column) of the
      interaction values equals the corresponding SHAP value (from
      pred_contribs), and the sum of the entire matrix equals the raw
      untransformed margin value of the prediction. Note the last row and
      column correspond to the bias term.

  * `:validate_features` - When this is `true`, validate that the Booster's and data's
      feature_names are identical. Otherwise, it is assumed that the
      feature_names are the same.

  * `:training` - Determines whether the prediction value is used for training. This
      can affect the `dart` booster, which performs dropouts during training iterations
      but uses all trees for inference. If you want to obtain result with dropouts, set
      this option to `true`. Also, the option is set to `true` when obtaining prediction for
      custom objective function.

  * `:iteration_range` - Specifies which layer of trees are used in prediction. For example, if a
      random forest is trained with 100 rounds. Specifying `iteration_range=(10,
      20)`, then only the forests built during [10, 20) (half open set) rounds are
      used in this prediction.

  * `:strict_shape` - When set to `true`, output shape is invariant to whether classification is used.
      For both value and margin prediction, the output shape is (n_samples,
      n_groups), n_groups == 1 when multi-class is not used. Defaults to `false`, in
      which case the output shape can be (n_samples, ) if multi-class is not used.

  Returns an Nx.Tensor containing the predictions.
  """
  @doc type: :train_pred
  def predict(%Booster{} = bst, x, opts \\ []) do
    x = Nx.concatenate(x)
    {dmat_opts, opts} = Keyword.split(opts, Internal.dmatrix_feature_opts())
    dmat = DMatrix.from_tensor(x, Keyword.put_new(dmat_opts, :format, :dense))
    Booster.predict(bst, dmat, opts)
  end

  @doc """
  Run prediction in-place, Unlike `EXGBoost.predict/2`, in-place prediction does not cache the prediction result.

  ## Options

  * `:base_margin` -  Base margin used for boosting from existing model.

  * `:missing` - Value used for missing values. If None, defaults to `Nx.Constants.nan()`.

  * `:predict_type` - One of:

    * `"value"`  - Output model prediction values.

    * `"margin"`  - Output the raw untransformed margin value.

  * `:output_margin` - Whether to output the raw untransformed margin value.

  * `:iteration_range` - See `EXGBoost.predict/2` for details.

  * `:strict_shape` - See `EXGBoost.predict/2` for details.

  Returns an Nx.Tensor containing the predictions.
  """
  @doc type: :train_pred
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

    case data do
      %Nx.Tensor{} = data ->
        data_interface = ArrayInterface.from_tensor(data) |> Jason.encode!()

        {shape, preds} =
          EXGBoost.NIF.booster_predict_from_dense(
            boostr.ref,
            data_interface,
            Jason.encode!(params),
            proxy
          )
          |> Internal.unwrap!()

        Nx.tensor(preds) |> Nx.reshape(shape)

      {%Nx.Tensor{} = indptr, %Nx.Tensor{} = indices, %Nx.Tensor{} = values, ncol} ->
        indptr_interface = ArrayInterface.from_tensor(indptr) |> Jason.encode!()
        indices_interface = ArrayInterface.from_tensor(indices) |> Jason.encode!()
        values_interface = ArrayInterface.from_tensor(values) |> Jason.encode!()

        {shape, preds} =
          EXGBoost.NIF.booster_predict_from_csr(
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

      data ->
        data = Nx.concatenate(data)
        data_interface = ArrayInterface.from_tensor(data) |> Jason.encode!()

        {shape, preds} =
          EXGBoost.NIF.booster_predict_from_dense(
            boostr.ref,
            data_interface,
            Jason.encode!(params),
            proxy
          )
          |> Internal.unwrap!()

        Nx.tensor(preds) |> Nx.reshape(shape)
    end
  end

  @format_opts [
    format: [
      type: {:in, [:json, :ubj]},
      default: :json,
      doc: """
      The format to serialize to. Can be either `:json` or `:ubj`.
      """
    ]
  ]

  @overwrite_opts [
    overwrite: [
      type: :boolean,
      default: false,
      doc: """
      Whether or not to overwrite the file if it already exists.
      """
    ]
  ]

  @load_opts [
    booster: [
      type: {:struct, Booster},
      doc: """
      The Booster to load the model into. If a Booster is provided, the model will be loaded into
      that Booster. Otherwise, a new Booster will be created. If a Booster is provided, model parameters
      will be merged with the existing Booster's parameters using Map.merge/2, where the parameters
      of the provided Booster take precedence.
      """
    ]
  ]

  @write_schema NimbleOptions.new!(@format_opts ++ @overwrite_opts)
  @dump_schema NimbleOptions.new!(@format_opts)
  @load_schema NimbleOptions.new!(@load_opts)

  @doc """
  Write a model to a file.

  ## Options
  #{NimbleOptions.docs(@write_schema)}
  """
  @doc type: :serialization
  @spec write_model(Booster.t(), String.t()) :: :ok | {:error, String.t()}
  def write_model(%Booster{} = booster, path, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @write_schema)
    EXGBoost.Booster.save(booster, opts ++ [path: path, serialize: :model])
  end

  @doc """
  Read a model from a file and return the Booster.
  """
  @doc type: :serialization
  @spec read_model(String.t()) :: EXGBoost.Booster.t()
  def read_model(path) do
    EXGBoost.Booster.load(path, deserialize: :model)
  end

  @doc """
  Dump a model to a binary encoded in the desired format.

  ## Options
  #{NimbleOptions.docs(@dump_schema)}
  """
  @spec dump_model(Booster.t()) :: binary()
  @doc type: :serialization
  def dump_model(%Booster{} = booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @dump_schema)
    EXGBoost.Booster.save(booster, opts ++ [serialize: :model, to: :buffer])
  end

  @doc """
  Read a model from a buffer and return the Booster.
  """
  @spec load_model(binary()) :: EXGBoost.Booster.t()
  @doc type: :serialization
  def load_model(buffer) do
    EXGBoost.Booster.load(buffer, deserialize: :model, from: :buffer)
  end

  @doc """
  Write a model config to a file as a JSON - encoded string.

  ## Options
  #{NimbleOptions.docs(@write_schema)}
  """
  @spec write_config(Booster.t(), String.t()) :: :ok | {:error, String.t()}
  @doc type: :serialization
  def write_config(%Booster{} = booster, path, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @write_schema)
    EXGBoost.Booster.save(booster, opts ++ [path: path, serialize: :config])
  end

  @doc """
  Dump a model config to a buffer as a JSON - encoded string.

  ## Options
  #{NimbleOptions.docs(@dump_schema)}
  """
  @spec dump_config(Booster.t()) :: binary()
  @doc type: :serialization
  def dump_config(%Booster{} = booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @dump_schema)
    EXGBoost.Booster.save(booster, opts ++ [serialize: :config, to: :buffer])
  end

  @doc """
  Create a new Booster from a config file. The config file must be from the output of `write_config/2`.

  ## Options
  #{NimbleOptions.docs(@load_schema)}
  """
  @spec read_config(String.t()) :: EXGBoost.Booster.t()
  @doc type: :serialization
  def read_config(path, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @load_schema)
    EXGBoost.Booster.load(path, opts ++ [deserialize: :config])
  end

  @doc """
  Create a new Booster from a config buffer. The config buffer must be from the output of `dump_config/2`.

  ## Options
  #{NimbleOptions.docs(@load_schema)}
  """
  @spec load_config(binary()) :: EXGBoost.Booster.t()
  @doc type: :serialization
  def load_config(buffer, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @load_schema)
    EXGBoost.Booster.load(buffer, opts ++ [deserialize: :config, from: :buffer])
  end

  @doc """
  Write a model's trained parameters to a file.

  ## Options
  #{NimbleOptions.docs(@write_schema)}
  """
  @spec write_weights(Booster.t(), String.t()) :: :ok | {:error, String.t()}
  @doc type: :serialization
  def write_weights(%Booster{} = booster, path, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @write_schema)
    EXGBoost.Booster.save(booster, opts ++ [path: path, serialize: :weights])
  end

  @doc """
  Dump a model's trained parameters to a buffer as a JSON-encoded binary.

  ## Options
  #{NimbleOptions.docs(@dump_schema)}
  """
  @spec dump_weights(Booster.t()) :: binary()
  @doc type: :serialization
  def dump_weights(%Booster{} = booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @dump_schema)
    EXGBoost.Booster.save(booster, opts ++ [serialize: :weights, to: :buffer])
  end

  @doc """
  Read a model's trained parameters from a file and return the Booster.
  """
  @spec read_weights(String.t()) :: EXGBoost.Booster.t()
  @doc type: :serialization
  def read_weights(path) do
    EXGBoost.Booster.load(path, deserialize: :weights)
  end

  @doc """
  Read a model's trained parameters from a buffer and return the Booster.
  """
  @spec load_weights(binary()) :: EXGBoost.Booster.t()
  @doc type: :serialization
  def load_weights(buffer) do
    EXGBoost.Booster.load(buffer, deserialize: :weights, from: :buffer)
  end

  @doc """
  Plot a tree from a Booster model and save it to a file.

  ## Options
  * `:format` - the format to export the graphic as, must be either of: `:json`, `:html`, `:png`, `:svg`, `:pdf`. By default the format is inferred from the file extension.
  * `:local_npm_prefix` - a relative path pointing to a local npm project directory where the necessary npm packages are installed. For instance, in Phoenix projects you may want to pass local_npm_prefix: "assets". By default the npm packages are searched for in the current directory and globally.
  * `:path` - the path to save the graphic to. If not provided, the graphic is returned as a VegaLite spec.
  * `:opts` - additional options to pass to `EXGBoost.Plotting.plot/2`. See `EXGBoost.Plotting` for more information.
  """
  @doc type: :plotting
  def plot_tree(booster, opts \\ []) do
    {path, opts} = Keyword.pop(opts, :path)
    {save_opts, opts} = Keyword.split(opts, [:format, :local_npm_prefix])
    vega = Plotting.plot(booster, opts)

    if path != nil do
      VegaLite.Export.save!(vega, path, save_opts)
    else
      vega
    end
  end
end
