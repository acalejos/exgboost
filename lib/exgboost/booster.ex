defmodule Exgboost.Booster do
  alias __MODULE__
  alias Exgboost.DMatrix
  alias Exgboost.Internal
  alias Exgboost.NIF
  @enforce_keys [:ref]
  defstruct [:ref, :best_iteration, :best_score]

  def booster(dmats, opts \\ [])

  def booster([%DMatrix{} | _] = dmats, opts) when is_list(dmats) do
    refs = Enum.map(dmats, & &1.ref)
    booster_ref = Exgboost.NIF.booster_create(refs) |> Internal.unwrap!()
    Booster.set_params(%Booster{ref: booster_ref}, opts)
  end

  def booster(%DMatrix{} = dmat, opts) do
    booster([dmat], opts)
  end

  @doc """
  Slice a model using boosting index. The slice m:n indicates taking all
  trees that were fit during the boosting rounds m, (m+1), (m+2), …, (n-1).
  """
  def slice(boostr, begin_layer, end_layer, step) do
    Exgboost.NIF.booster_slice(boostr.ref, begin_layer, end_layer, step) |> Internal.unwrap!()
  end

  @doc """
  Boost the booster for one iteration, with customized gradient statistics.
  """
  def boost(
        %Booster{} = booster,
        %DMatrix{} = dmatrix,
        %Nx.Tensor{} = grad,
        %Nx.Tensor{} = hess
      ) do
    Internal.validate_type!(grad, {:f, 32})
    Internal.validate_type!(hess, {:f, 32})

    if Nx.shape(grad) != Nx.shape(hess) do
      raise ArgumentError,
            "grad and hess must have the same shape, got #{inspect(Nx.shape(grad))} and #{inspect(Nx.shape(hess))}"
    end

    Exgboost.NIF.booster_boost_one_iter(
      booster.ref,
      dmatrix.ref,
      Nx.to_binary(grad),
      Nx.to_binary(hess)
    )
  end

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

        Keyword.fetch!(opts, :pred_contribs) ->
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
      |> Internal.unwrap!()

    Nx.tensor(preds) |> Nx.reshape(shape)
  end

  def set_params(%Booster{} = booster, params \\ []) do
    # TODO: List of params here: https://xgboost.readthedocs.io/en/latest/parameter.html
    # Eventually we should validate, but there's so many, for now we will let XGBoost fail
    # on invalid params
    for {key, value} <- params do
      Exgboost.NIF.booster_set_param(booster.ref, Atom.to_string(key), value)
    end

    booster
  end

  @doc """
  Set attributes for booster.

  Key value pairs are passed as options. You can set an existing key to :nil to
  delete the attribute
  """
  def set_attr(booster, attrs \\ []) do
    Enum.each(attrs, fn {key, value} ->
      Exgboost.NIF.booster_set_attr(booster.ref, Atom.to_string(key), value)
    end)

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

  def get_best_iteration(booster), do: get_attr(booster, "best_iteration")

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
  Evaluate the model on mat.

  ## Options
    * `name` - The name of the dataset.

    * `iteration` - The current iteration number.

    Returns the evaluation result string.
  """
  def eval(%Booster{} = booster, %DMatrix{} = data, opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, "eval")
    {iteration, opts} = Keyword.pop(opts, :iteration, 0)
    Internal.validate_features!(booster, data)
    eval_set(booster, [{data, name}], iteration, opts)
  end

  @doc """
  Evaluate a set of data.

  ## Options

  * `iteration` - Current iteration.
  * `feval` - Custom evaluation function.

  Returns the resulting metrics as a list of 2-tuples in the form of {eval_metric, value}.
  """
  def eval_set(%Booster{} = booster, evals, iteration, opts \\ []) when is_list(evals) do
    opts = Keyword.validate!(opts, feval: nil, output_margin: true)
    feval = opts[:feval]
    output_margin = opts[:output_margin]
    Enum.each(evals, &Internal.validate_features!(booster, elem(&1, 0)))
    {dmats_refs, evnames} = Enum.unzip(evals)
    dmats_refs = Enum.map(dmats_refs, & &1.ref)

    msg =
      Exgboost.NIF.booster_eval_one_iter(booster.ref, iteration, dmats_refs, evnames)
      |> Internal.unwrap!()

    res =
      Regex.scan(~r/[[:blank:]](\w+)-(\w+):(-?\d+\.?\d+)/, to_string(msg), capture: :all_but_first)
      |> Enum.map(fn [ev_name | [metric_name | [value]]] ->
        {fval, _rem} = Float.parse(value)
        {ev_name, metric_name, fval}
      end)

    if feval do
      Enum.each(evals, fn {dmat, evname} ->
        feval_ret =
          feval.(
            Booster.predict(booster, dmat, training: false, output_margin: output_margin),
            dmat
          )

        if is_list(feval_ret) do
          Enum.each(feval_ret, fn {name, value} ->
            [{evname, name, value} | res]
          end)
        else
          {name, value} = feval_ret
          [{evname, name, value} | res]
        end
      end)
    else
      res
    end
  end

  @doc """
  Update for one iteration, with objective function calculated internally.

  If an objective function is provided rather than a number of iterations, this
  updates for one iteration, with objective function defined by the user.

  See [Custom Objective](https://xgboost.readthedocs.io/en/latest/tutorials/custom_metric_obj.html) for details.
  """
  def update(%Booster{} = booster, %DMatrix{} = dmatrix, iteration, objective)
      when is_integer(iteration) do
    if is_function(objective, 2) do
      pred = Booster.predict(booster, dmatrix, output_margin: true, training: true)
      {grad, hess} = objective.(pred, dmatrix)
      boost(booster, dmatrix, grad, hess)
    else
      NIF.booster_update_one_iter(booster.ref, dmatrix.ref, iteration) |> Internal.unwrap!()
    end
  end
end
