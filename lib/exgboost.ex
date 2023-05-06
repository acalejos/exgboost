defmodule Exgboost do
  alias Exgboost.Booster
  alias Exgboost.DMatrix
  import Exgboost.Internal

  def xgboost_build_info, do: Exgboost.NIF.xgboost_build_info() |> unwrap! |> Jason.decode!()

  def xgboost_version, do: Exgboost.NIF.xgboost_version() |> unwrap!
  def dmatrix(value, opts \\ [])

  def dmatrix(input, opts) when is_list(input) do
    dmatrix(Nx.tensor(input), opts)
  end

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

    set_params(%DMatrix{ref: dmat, format: format}, Keyword.merge(meta_opts, str_opts))
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

    set_params(%DMatrix{ref: dmat, format: format}, Keyword.merge(meta_opts, str_opts))
  end

  def set_params(value, opts \\ [])

  def set_params(%DMatrix{} = dmat, opts) do
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

  def set_params(%Booster{} = booster, opts) do
    # opts = Keyword.validate!(opts, [:params, :cache])
    # TODO: List of params here: https://xgboost.readthedocs.io/en/latest/parameter.html
    # Eventually we should validate, but there's so many, for now we will let XGBoost fail
    # on invalid params
    for {key, value} <- opts do
      Exgboost.NIF.booster_set_param(booster.ref, Atom.to_string(key), value)
    end

    booster
  end

  def booster(dmats, opts \\ [])

  def booster(dmats, opts) when is_list(dmats) do
    refs = Enum.map(dmats, & &1.ref)
    booster_ref = Exgboost.NIF.booster_create(refs) |> unwrap!() |> IO.inspect()
    set_params(%Booster{ref: booster_ref}, opts)
  end

  def booster(%DMatrix{} = dmat, opts) do
    booster([dmat], opts)
  end

  def train(%DMatrix{} = dmat, opts \\ []) do
    opts = Keyword.validate!(opts, [:obj, num_boost_rounds: 10, params: %{}])

    {booster_opts, opts} = Keyword.pop!(opts, :params)
    # TODO: Find exhaustive list of params to use String.to_existing_atom()
    booster_opts = Keyword.new(booster_opts, fn {key, value} -> {key, value} end)

    bst = Exgboost.booster(dmat, booster_opts)
    Exgboost.Internal._train(bst, dmat, opts)
  end

  # TODO: Inplace Prediction

  @doc """
  Predict with a booster.
  Predict with a Booster and DMatrix containing data.
  The full model will be used unless `iteration_range` is specified,
  meaning user have to either slice the model or use the ``best_iteration``
  attribute to get prediction from best model returned from early stopping.

  Parameters
  ----------
  booster:
      Booster instance.
  data :
      The dmatrix storing the input.

  output_margin :
      Whether to output the raw untransformed margin value.

  pred_leaf :
      When this option is on, the output will be a matrix of (nsample,
      ntrees) with each record indicating the predicted leaf index of
      each sample in each tree.  Note that the leaf index of a tree is
      unique per tree, so you may find leaf 1 in both tree 1 and tree 0.

  pred_contribs :
      When this is True the output will be a matrix of size (nsample,
      nfeats + 1) with each record indicating the feature contributions
      (SHAP values) for that prediction. The sum of all feature
      contributions is equal to the raw untransformed margin value of the
      prediction. Note the final column is the bias term.

  approx_contribs :
      Approximate the contributions of each feature.  Used when ``pred_contribs`` or
      ``pred_interactions`` is set to True.  Changing the default of this parameter
      (False) is not recommended.

  pred_interactions :
      When this is True the output will be a matrix of size (nsample,
      nfeats + 1, nfeats + 1) indicating the SHAP interaction values for
      each pair of features. The sum of each row (or column) of the
      interaction values equals the corresponding SHAP value (from
      pred_contribs), and the sum of the entire matrix equals the raw
      untransformed margin value of the prediction. Note the last row and
      column correspond to the bias term.

  validate_features :
      When this is True, validate that the Booster's and data's
      feature_names are identical.  Otherwise, it is assumed that the
      feature_names are the same.

  training :
      Whether the prediction value is used for training.  This can effect `dart`
      booster, which performs dropouts during training iterations but use all trees
      for inference. If you want to obtain result with dropouts, set this parameter
      to `True`.  Also, the parameter is set to true when obtaining prediction for
      custom objective function.

      .. versionadded:: 1.0.0

  iteration_range :
      Specifies which layer of trees are used in prediction.  For example, if a
      random forest is trained with 100 rounds.  Specifying `iteration_range=(10,
      20)`, then only the forests built during [10, 20) (half open set) rounds are
      used in this prediction.

      .. versionadded:: 1.4.0

  strict_shape :
      When set to True, output shape is invariant to whether classification is used.
      For both value and margin prediction, the output shape is (n_samples,
      n_groups), n_groups == 1 when multi-class is not used.  Default to False, in
      which case the output shape can be (n_samples, ) if multi-class is not used.

      .. versionadded:: 1.4.0

  Returns
  -------
  prediction : Nx.tensor

  """
  def predict(%Booster{} = booster, %DMatrix{} = data, opts \\ []) do
    opts =
      Keyword.validate!(opts,
        output_margin: false,
        pred_leaf: false,
        pred_contribs: false,
        approx_contribs: false,
        pred_interactions: false,
        validate_features: true,
        training: false,
        iteration_range: {0, 0},
        strict_shape: false
      )

    if Keyword.fetch!(opts, :validate_features) do
      Exgboost.Internal.validate_features!(booster, data)
    end

    approx_contribs = Keyword.fetch!(opts, :approx_contribs)

    type_count =
      Keyword.take(opts, [:output_margin, :pred_leaf, :pred_contribs, :pred_interactions])
      |> Keyword.values()
      |> Enum.count(& &1)

    if type_count > 1 do
      raise ArgumentError,
            "Only one of :output_margin, :pred_leaf, :pred_contribs, :pred_interactions can be set to true"
    end

    type =
      cond do
        Keyword.fetch!(opts, :output_margin) ->
          1

        Keyword.fetch!(opts, :pred_contrib) ->
          if approx_contribs, do: 3, else: 2

        Keyword.fetch!(opts, :pred_interactions) ->
          if approx_contribs, do: 5, else: 4

        Keyword.fetch!(opts, :pred_leaf) ->
          6

        true ->
          0
      end

    {left_range, right_range} = Keyword.fetch!(opts, :iteration_range)

    config = %{
      type: type,
      training: Keyword.fetch!(opts, :training),
      iteration_begin: left_range,
      iteration_end: right_range,
      strict_shape: Keyword.fetch!(opts, :strict_shape)
    }

    {shape, preds} =
      Exgboost.NIF.booster_predict_from_dmatrix(booster.ref, data.ref, Jason.encode!(config))
      |> unwrap!()

    Nx.tensor(preds) |> Nx.reshape(shape)
  end
end
