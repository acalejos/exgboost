defmodule EXGBoost.Booster do
  @moduledoc """
  A Booster is the main object used for training and prediction. It is a wrapper around the
  underlying XGBoost C API.  Booster have three main concepts for tracking associated data:
  parameters, attributes, and features. Parameters are used to configure the Booster and are
  from a set of valid options (such as `tree_depth` and `eta` -- refer to `EXGBoost.Parameters` for full list).
  Attributes are user-provided key-value pairs that are assigned to a Booster (such as `best_iteration` and `best_score`).
  Features are used to track the metadata associated with the features used in training (such as `feature_names` and `feature_types`).

  ## Training

  When using `EXGBoost.train/2`, a Booster is created and trained automatically with the given parameters.
  If you need more control over the training process, please refer to `EXGBoost.Training.Callback` for
  guidance on how to inject custom logic into the training process.

  ## Creation

  A Booster can be created using `EXGBoost.Booster.booster` from a list of DMatrices, a single DMatrix, or
  another Booster. If a list of DMatrices is provided, the first DMatrix is used as the training
  data and the rest are used for evaluation. If a single DMatrix is provided, it is used as the
  training data. If another Booster is provided, it is copied and returned as a new Booster with
  the same configuration -- if params are provided, they will override the configuration of the
  copied Booster.

  ## Serliaztion

  A Booster can be serialized to a file using `EXGBoost.Booster.save_to_file/3` and loaded from a file
  using `EXGBoost.Booster.from_file/2`. The file format can be specified using the `:format` option
  which can be either `:json` or `:ubj`. The default is `:json`. If the file already exists, it will
  be overwritten by default.  Boosters can either be serialized to a file or to a binary string.
  Boosters can be serialized in three different ways: configuration only, configuration and model, or
  model only. Any function that uses the `to` and `from` `buffer` functions will serialize the Booster
  to a binary string. The `to` and `from` `file` functions will serialize the Booster to a file.
  Functions named with `weights` will serialize the model weights only. Functions named with `config` will
  serialize the configuration only. Functions that specify `model` will serialize both the model weights
  and the configuration.

  ### Output Formats
  - 'file' - Save to a file.
  - 'buffer' - Save to a binary string.

  ### Output Contents
  - 'config' - Save the configuration only.
  - 'weights' - Save the model weights only.
  - 'model' - Save both the model weights and the configuration.
  """
  alias EXGBoost.DMatrix
  alias EXGBoost.Internal
  alias EXGBoost.NIF
  @enforce_keys [:ref]
  defstruct [:ref, :best_iteration, :best_score]

  @save_schema [
    to: [
      type: {:in, [:file, :buffer]},
      default: :file,
      doc: """
      The output format. Can be either `:file` or `:buffer`.
      """
    ],
    path: [
      type: :string,
      doc: """
      The path to the file to save to. Required if `to` is `:file`.
      """
    ],
    serialize: [
      type: {:in, [:config, :weights, :model]},
      default: :model,
      doc: """
      The contents to serialize. Can be either `:config`, `:weights`, or `:model`.
      """
    ],
    format: [
      type: {:in, [:json, :ubj]},
      default: :json,
      doc: """
      The format to serialize to. Can be either `:json` or `:ubj`.
      """
    ],
    overwrite: [
      type: :boolean,
      default: false,
      doc: """
      Whether or not to overwrite the file if it already exists.
      """
    ]
  ]

  @load_schema [
    from: [
      type: {:in, [:file, :buffer]},
      default: :file,
      doc: """
      The input format. Can be either `:file` or `:buffer`.
      """
    ],
    deserialize: [
      type: {:in, [:config, :weights, :model]},
      default: :model,
      doc: """
      The contents to deserialize. Can be either `:config`, `:weights`, or `:model`.
      """
    ],
    booster: [
      type: {:struct, __MODULE__},
      doc: """
      The Booster to load the model into. If not provided, a new Booster will be created.
      """
    ]
  ]

  @save_schema NimbleOptions.new!(@save_schema)
  @load_schema NimbleOptions.new!(@load_schema)

  @doc """
  Create a new Booster.

  A Booster can be created from a list of DMatrices, a single DMatrix, or
  another Booster. If a list of DMatrices is provided, the first DMatrix is used as the training
  data and the rest are used for evaluation. If a single DMatrix is provided, it is used as the
  training data. If another Booster is provided, it is copied and returned as a new Booster with
  the same configuration -- if params are provided, they will override the configuration of the
  copied Booster.

  ## Options
  Refer to `EXGBoost.Parameters` for a list of valid options.
  """
  def booster(dmats, opts \\ [])

  def booster(dmats, opts) when is_list(dmats) do
    opts = EXGBoost.Parameters.validate!(opts)
    refs = Enum.map(dmats, & &1.ref)
    booster_ref = EXGBoost.NIF.booster_create(refs) |> Internal.unwrap!()
    set_params(%__MODULE__{ref: booster_ref}, opts)
  end

  def booster(%DMatrix{} = dmat, opts) do
    booster([dmat], opts)
  end

  def booster(%__MODULE__{} = bst, opts) do
    opts = EXGBoost.Parameters.validate!(opts)
    boostr_bytes = EXGBoost.NIF.booster_serialize_to_buffer(bst.ref) |> Internal.unwrap!()
    booster_ref = EXGBoost.NIF.booster_deserialize_from_buffer(boostr_bytes) |> Internal.unwrap!()
    set_params(%__MODULE__{ref: booster_ref}, opts)
  end

  def from_weights_file(path, opts \\ []) do
    unless File.exists?(path) and File.regular?(path) do
      raise ArgumentError, "File not found: #{path}"
    end
    opts = EXGBoost.Parameters.validate!(opts)
    booster_ref = EXGBoost.NIF.booster_load_model(path) |> Internal.unwrap!()
    set_params(%__MODULE__{ref: booster_ref}, opts)
  end

  @doc """
  Save a Booster to the specified source.

  ## Options
  #{NimbleOptions.docs(@save_schema)}
  """
  def save(%__MODULE__{} = booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts,@save_schema)
    if opts[:to] == :file do
      if is_nil(opts[:path]) do
        raise ArgumentError, "Missing required option: `path`"
      end
      filepath = "#{Path.absname(opts[:path])}.#{opts[:format]}"
      if !opts[:overwrite] and File.exists?(filepath) do
        raise ArgumentError, "File already exists: #{filepath} -- set `overwrite: true` to overwrite"
      end
      case opts[:serialize] do
        :config -> EXGBoost.NIF.booster_save_json_config(booster.ref) |> Internal.unwrap!() |> then(&File.write!(filepath,&1))
        :model -> EXGBoost.NIF.booster_serialize_to_buffer(booster.ref) |> Internal.unwrap!() |> then(&File.write!(filepath,&1))
        :weights -> EXGBoost.NIF.booster_save_model(booster.ref, filepath) |> Internal.unwrap!()
      end
    else
      case opts[:serialize] do
        :config -> EXGBoost.NIF.booster_save_json_config(booster.ref) |> Internal.unwrap!()
        :model -> EXGBoost.NIF.booster_serialize_to_buffer(booster.ref) |> Internal.unwrap!()
        :weights -> EXGBoost.NIF.booster_save_model_to_buffer(booster.ref, Jason.encode!(%{format: opts[:format]})) |> Internal.unwrap!()
      end
    end
  end

  @doc """
  Load a Booster from the specified source. If a Booster is provided, the model will be loaded into
  that Booster. Otherwise, a new Booster will be created. If a Booster is provided, model parameters
  will be merged with the existing Booster's parameters using Map.merge/2, where the parameters
  of the provided Booster take precedence.

  ## Options
  #{NimbleOptions.docs(@load_schema)}
  """
  def load(source, opts \\ []) do
    opts = NimbleOptions.validate!(opts,@load_schema)
    booster = if opts[:booster] do
      opts[:booster]
    else
      booster([])
    end
    source =
    if opts[:from] == :file do
      filepath = Path.absname(source)
      if not File.exists?(filepath) do
        raise ArgumentError, "File not found: #{filepath}"
      end
      File.read!(filepath)
    else
      source
    end
    booster_ref =
      case opts[:deserialize] do
        :config ->
          config =
            if opts[:booster] do
              Map.merge(get_config(booster), source |> Jason.decode!()) |> Jason.encode!()
            else
              source
            end
          EXGBoost.NIF.booster_load_json_config(booster.ref, config) |> Internal.unwrap!()
        :model -> EXGBoost.NIF.booster_deserialize_from_buffer(source) |> Internal.unwrap!()
        :weights -> EXGBoost.NIF.booster_load_model_from_buffer(source) |> Internal.unwrap!()
      end
    struct(booster, ref: booster_ref)
  end

  @doc """
  Get Booster configuration as Map. Please note that if you wish to use this configuration to load a new Booster, please
  use the `load_config/2` function instead. The configuration returned by this function is not compatible with the
  `set_params/2` function.
  """
  def get_config(%__MODULE__{} = booster) do
    EXGBoost.NIF.booster_save_json_config(booster.ref) |> Internal.unwrap!() |> Jason.decode!()
  end

  @doc """
  Slice a model using boosting index. The slice m:n indicates taking all
  trees that were fit during the boosting rounds m, (m+1), (m+2), …, (n-1).
  """
  def slice(boostr, begin_layer, end_layer, step) do
    EXGBoost.NIF.booster_slice(boostr.ref, begin_layer, end_layer, step) |> Internal.unwrap!()
  end

  @doc """
  Boost the booster for one iteration, with customized gradient statistics.
  """
  def boost(
        %__MODULE__{} = booster,
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

    EXGBoost.NIF.booster_boost_one_iter(
      booster.ref,
      dmatrix.ref,
      Nx.to_binary(grad),
      Nx.to_binary(hess)
    )
  end

  def predict(%__MODULE__{} = booster, %DMatrix{} = data, opts \\ []) do
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
      EXGBoost.Internal.validate_features!(booster, data)
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
      EXGBoost.NIF.booster_predict_from_dmatrix(booster.ref, data.ref, Jason.encode!(config))
      |> Internal.unwrap!()

    Nx.tensor(preds) |> Nx.reshape(shape)
  end

  def set_params(%__MODULE__{} = booster, params \\ []) do
    for {key, value} <- params do
      cond do
        Keyword.keyword?(value) ->
          set_params(booster, value)

        is_list(value) ->
            Enum.each(value, fn v ->
              EXGBoost.NIF.booster_set_param(booster.ref, Atom.to_string(key), to_string(v))
            end)

        is_atom(key) ->
          EXGBoost.NIF.booster_set_param(booster.ref, Atom.to_string(key), to_string(value))

        is_binary(key) ->
          EXGBoost.NIF.booster_set_param(booster.ref, key, to_string(value))

        true ->
          raise ArgumentError, "Invalid key #{inspect(key)}"
      end
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
      EXGBoost.NIF.booster_set_attr(booster.ref, Atom.to_string(key), value)
    end)

    booster
  end

  @doc """
  Get the names of the features for the booster.
  """
  def get_feature_names(booster),
    do:
      EXGBoost.NIF.booster_get_str_feature_info(booster.ref, "feature_name") |> Internal.unwrap!()

  @doc """
  Get the type for each feature in the booster
  """
  def get_feature_types(booster),
    do:
      EXGBoost.NIF.booster_get_str_feature_info(booster.ref, "feature_type") |> Internal.unwrap!()

  @doc """
  Get the number of features for the booster.
  """
  def get_num_features(booster),
    do: EXGBoost.NIF.booster_get_num_feature(booster.ref) |> Internal.unwrap!()

  @doc """
  Get the best iteration for the booster.
  """
  def get_best_iteration(booster), do: get_attr(booster, "best_iteration")

  @doc"""
  Get the attribute names for the booster.
  """
  def get_attrs(booster),
    do: EXGBoost.NIF.booster_get_attr_names(booster.ref) |> Internal.unwrap!()

  @doc """
  Get the number of boosted rounds for the booster.
  """
  def get_boosted_rounds(booster) do
    EXGBoost.NIF.booster_boosted_rounds(booster.ref) |> Internal.unwrap!()
  end

  @doc """
  Get the attribute value for the given key.
  """
  def get_attr(booster, attr) do
    attrs = get_attrs(booster)

    if Enum.member?(attrs, attr) do
      EXGBoost.NIF.booster_get_attr(booster.ref, attr) |> Internal.unwrap!()
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
  def eval(%__MODULE__{} = booster, %DMatrix{} = data, opts \\ []) do
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
  def eval_set(%__MODULE__{} = booster, evals, iteration, opts \\ []) when is_list(evals) do
    opts = Keyword.validate!(opts, feval: nil, output_margin: true)
    feval = opts[:feval]
    output_margin = opts[:output_margin]
    Enum.each(evals, &Internal.validate_features!(booster, elem(&1, 0)))
    {dmats_refs, evnames} = Enum.unzip(evals)
    dmats_refs = Enum.map(dmats_refs, & &1.ref)

    msg =
      EXGBoost.NIF.booster_eval_one_iter(booster.ref, iteration, dmats_refs, evnames)
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
            predict(booster, dmat, training: false, output_margin: output_margin),
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
  def update(%__MODULE__{} = booster, %DMatrix{} = dmatrix, iteration, objective)
      when is_integer(iteration) do
    if is_function(objective, 2) do
      pred = predict(booster, dmatrix, output_margin: true, training: true)
      {grad, hess} = objective.(pred, dmatrix)
      boost(booster, dmatrix, grad, hess)
    else
      NIF.booster_update_one_iter(booster.ref, dmatrix.ref, iteration) |> Internal.unwrap!()
    end
  end
end
