defmodule Exgboost.Parameters do
  @global_params [
    verbosity: [
      type: {:custom, Exgboost.Parameters, :validate_verbosity, []}
    ],
    use_rmm: [
      type: :boolean,
      default: false
    ]
  ]

  @general_params [
    booster: [
      type: {:in, [:gbtree, :gblinear, :dart]},
      default: :gbtree
    ],
    verbosity: [
      type: {:custom, Exgboost.Parameters, :validate_verbosity, []},
      default: :silent
    ],
    validate_parameters: [
      type: :boolean,
      default: true
    ],
    nthread: [
      type: :non_neg_integer,
      default: 0
    ],
    disable_default_eval_metric: [
      type: :boolean,
      default: false
    ],
    num_features: [
      type: :non_neg_integer
    ]
  ]

  @tree_booster_params [
    eta: [
      type: :float,
      default: 0.3
    ],
    gamma: [
      type: :float,
      default: 0.0
    ],
    max_depth: [
      type: :pos_integer,
      default: 6
    ],
    min_child_weight: [
      type: :non_neg_integer,
      default: 1
    ],
    max_delta_step: [
      type: :non_neg_integer,
      default: 0
    ],
    subsample: [
      type:
        {:custom, Exgboost.Parameters, :in_range,
         [[min: 0, max: 1, left: :exclusive, right: :inclusive]]},
      default: 1.0
    ],
    colsample_bytree: [
      type:
        {:custom, Exgboost.Parameters, :in_range,
         [[min: 0, max: 1, left: :exclusive, right: :inclusive]]},
      default: 1
    ],
    colsample_bylevel: [
      type:
        {:custom, Exgboost.Parameters, :in_range,
         [[min: 0, max: 1, left: :exclusive, right: :inclusive]]},
      default: 1
    ],
    colsample_bynode: [
      type:
        {:custom, Exgboost.Parameters, :in_range,
         [[min: 0, max: 1, left: :exclusive, right: :inclusive]]},
      default: 1
    ],
    lambda: [
      type: {:custom, Exgboost.Parameters, :in_range, [[min: 0, max: Nx.Constants.infinity()]]},
      default: 1
    ],
    reg_lambda: [
      type: {:custom, Exgboost.Parameters, :in_range, [[min: 0, max: Nx.Constants.infinity()]]},
      default: 1
    ],
    alpha: [
      type: {:custom, Exgboost.Parameters, :in_range, [[min: 0, max: Nx.Constants.infinity()]]},
      default: 0
    ],
    reg_alpha: [
      type: {:custom, Exgboost.Parameters, :in_range, [[min: 0, max: Nx.Constants.infinity()]]},
      default: 0
    ],
    tree_method: [
      type: {:in, [:auto, :exact, :approx, :hist, :gpu_hist]},
      default: :auto
    ],
    scale_pos_weight: [
      type: :float,
      default: 1.0
    ],
    updater: [
      type: {:custom, Exgboost.Parameters, :validate_tree_updater, []}
    ],
    refresh_leaf: [
      type: {:in, [0, 1]},
      default: 1
    ],
    process_type: [
      type: {:in, [:default, :update]},
      default: :default
    ],
    grow_policy: [
      type: {:in, [:depthwise, :lossguide]},
      default: :depthwise
    ],
    max_leaves: [
      type: :non_neg_integer,
      default: 0
    ],
    max_bin: [
      type: :pos_integer,
      default: 256
    ],
    predictor: [
      type: {:in, [:auto, :cpu_predictor, :gpu_predictor]},
      default: :auto
    ],
    num_parallel_tree: [
      type: :non_neg_integer,
      default: 1
    ],
    monotone_constraints: [
      type: {:list, {:or, [:float, :integer]}}
    ],
    interaction_constraints: [
      type: {:list, {:list, :integer}}
    ],
    multi_strategy: [
      type: {:in, [:one_output_per_tree, :multi_output_tree]},
      default: :one_output_per_tree
    ]
  ]

  @dart_booster_params @tree_booster_params ++
                         [
                           sample_type: [
                             type: {:in, [:uniform, :weighted]},
                             default: :uniform
                           ],
                           normalize_type: [
                             type: {:in, [:tree, :forest]},
                             default: :tree
                           ],
                           rate_drop: [
                             type:
                               {:custom, Exgboost.Parameters, :in_range,
                                [[min: 0, max: 1, left: :inclusive, right: :inclusive]]},
                             default: 0.0
                           ],
                           one_drop: [
                             type: {:in, [0, 1]},
                             default: 0
                           ],
                           skip_drop: [
                             type:
                               {:custom, Exgboost.Parameters, :in_range,
                                [[min: 0, max: 1, left: :inclusive, right: :inclusive]]},
                             default: 0.0
                           ]
                         ]

  @linear_booster_params [
    lambda: [
      type: :float,
      default: 0.0
    ],
    alpha: [
      type: :float,
      default: 0.0
    ],
    updater: [
      type: {:in, [:shotgun, :coord_descent]},
      default: :shotgun
    ],
    feature_selector: [
      type: {:in, [:cyclic, :shuffle, :random, :greedy, :thrifty]},
      default: :cyclic
    ],
    top_k: [
      type: :non_neg_integer,
      default: 0
    ]
  ]

  @learning_task_params [
    objective: [
      type: {:custom, Exgboost.Parameters, :validate_objective, []},
      default: :reg_squarederror
    ],
    base_score: [
      type: :float
    ],
    eval_metric: [
      type: {:custom, Exgboost.Parameters, :validate_eval_metric, []}
    ],
    seed: [
      type: :non_neg_integer,
      default: 0
    ],
    set_seed_per_iteration: [
      type: :boolean,
      default: false
    ]
  ]

  @tweedie_params [
    tweedie_variance_power: [
      type:
        {:custom, Exgboost.Parameters, :in_range,
         [[min: 1, max: 2, left: :exclusive, right: :exclusive]]},
      default: 1.5
    ]
  ]

  @pseudohubererror_params [
    huber_slope: [
      type: {:custom, Exgboost.Parameters, :in_range, [[min: 0, max: Nx.Constants.infinity()]]},
      default: 1.0
    ]
  ]

  @quantileerror_params [
    quantile_alpha: [
      type:
        {:custom, Exgboost.Parameters, :in_range,
         [[min: 0, max: 1, left: :exclusive, right: :exclusive]]},
      default: 0.5
    ]
  ]

  @survival_params [
    aft_loss_distribution: [
      type: {:in, [:normal, :logistic, :extreme]},
      default: :normal
    ]
  ]

  @ranking_params [
    lambdarank_pair_method: [
      type: {:in, [:mean, :topk]},
      default: :mean
    ],
    lambdarank_num_pair_per_sample: [
      type: {:custom, Exgboost.Parameters, :in_range, [[min: 1, max: Nx.Constants.infinity()]]}
    ],
    lambdarank_unbiased: [
      type: :boolean,
      default: false
    ],
    lambdarank_bias_norm: [
      type: {:in, [1.0, 2.0]},
      default: 2.0
    ],
    ndcg_exp_gain: [
      type: :boolean,
      default: true
    ]
  ]

  def validate_verbosity(x) do
    case x do
      :silent ->
        {:ok, 0}

      :warning ->
        {:ok, 1}

      :info ->
        {:ok, 2}

      :debug ->
        {:ok, 3}

      _ ->
        {:error,
         "Parameter `verbosity` must be in [:silent, :warning, :info, :debug], got #{inspect(x)}"}
    end
  end

  def validate_eval_metric(x) do
    x = if is_list(x), do: x, else: [x]

    metrics =
      Enum.map(x, fn y ->
        cond do
          String.contains?(to_string(y), "@") or String.ends_with?(to_string(y), "-") ->
            y

          y in [
            :rmse,
            :rmsle,
            :mae,
            :mape,
            :mphe,
            :logloss,
            :error,
            :merror,
            :mlogloss,
            :auc,
            :aucpr,
            :ndcg,
            :map,
            :poisson_nloglik,
            :gamma_nloglik,
            :cox_nloglik,
            :gamma_deviance,
            :tweedie_nloglik,
            :aft_nloglik,
            :interval_regression_accuracy
          ] ->
            Atom.to_string(y) |> String.replace("_", "-")

          true ->
            raise ArgumentError,
                  "Parameter `eval_metric` must be in [:rmse, :mae, :logloss, :error, :error, :merror, :mlogloss, :auc, :aucpr, :ndcg, :map, :ndcg, :map, :ndcg, :map, :poisson_nloglik, :gamma_nloglik, :gamma_deviance, :tweedie_nloglik, :tweedie_deviance], got #{inspect(y)}"
        end
      end)

    {:ok, metrics}
  end

  def validate_objective(x) do
    if(
      x in [
        :reg_squarederror,
        :reg_squaredlogerror,
        :reg_logistic,
        :reg_pseudohubererror,
        :reg_absoluteerror,
        :reg_quantileerror,
        :binary_logistic,
        :binary_logitraw,
        :binary_hinge,
        :count_poisson,
        :survival_cox,
        :survival_aft,
        :multi_softmax,
        :multi_softprob,
        :rank_ndcg,
        :rank_map,
        :rank_pairwise,
        :reg_gamma,
        :reg_tweedie
      ],
      do: {:ok, Atom.to_string(x) |> String.replace("_", ":")},
      else:
        {:error,
         "Parameter `objective` must be in [:reg_squarederror, :reg_squaredlogerror, :reg_logistic, :reg_pseudohubererror, :reg_absoluteerror, :reg_quantileerror, :binary_logistic, :binary_logitraw, :binary_hinge, :count_poisson, :survival_cox, :survival_aft, :multi_softmax, :multi_softprob, :rank_ndcg, :rank_map, :rank_pairwise, :reg_gamma, :reg_tweedie], got #{inspect(x)}"}
    )
  end

  def validate_tree_updater(values) when is_list(values) do
    case values do
      [single] ->
        if single in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh] do
          {:ok, single}
        else
          {:error,
           "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh], got #{inspect(single)}"}
        end

      [_head | _tail] ->
        x = Enum.uniq(values)

        if MapSet.subset?(
             MapSet.new(x),
             MapSet.new([
               :grow_colmaker,
               :prune,
               :refresh,
               :grow_histmaker,
               :sync,
               :refresh
             ])
           ),
           do: {:ok, Enum.map(x, &to_string/1) |> Enum.join(",")},
           else:
             {:error,
              "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh], got #{inspect(x)}"}

      _ ->
        {:error,
         "Parameter `updater` must only contain [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh], got #{inspect(values)}"}
    end
  end

  def validate_tree_updater(single) when is_atom(single) do
    if single in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh] do
      {:ok, single}
    else
      {:error,
       "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh], got #{inspect(single)}"}
    end
  end

  def in_range(value, opts \\ []) when is_list(opts) do
    opts = Keyword.validate!(opts, min: 0, max: 1, left: :inclusive, right: :inclusive)
    left = Keyword.fetch!(opts, :left)
    right = Keyword.fetch!(opts, :right)
    min = Keyword.fetch!(opts, :min)
    max = Keyword.fetch!(opts, :max)

    case {left, right} do
      {:inclusive, :inclusive} ->
        if value >= min and value <= max,
          do: {:ok, value},
          else:
            {:error,
             "Value #{inspect(value)} must be in range [#{inspect(min)}, #{inspect(max)}]"}

      {:inclusive, :exclusive} ->
        if value >= min and value < max,
          do: {:ok, value},
          else:
            {:error, "Value #{inspect(value)} must be in range [#{inspect(min)}, #{inspect(max)}"}

      {:exclusive, :inclusive} ->
        if value > min and value <= max,
          do: {:ok, value},
          else:
            {:error,
             "Value #{inspect(value)} must be in range (#{inspect(min)}, #{inspect(max)}]"}

      {:exclusive, :exclusive} ->
        if value > min and value < max,
          do: {:ok, value},
          else:
            {:error,
             "Value #{inspect(value)} must be in range (#{inspect(min)}, #{inspect(max)})"}

      _ ->
        raise ArgumentError, "Invalid range specification"
    end
  end

  @global_schema NimbleOptions.new!(@global_params)
  @general_schema NimbleOptions.new!(@general_params)
  @linear_booster_schema NimbleOptions.new!(@linear_booster_params)
  @tree_booster_schema NimbleOptions.new!(@tree_booster_params)
  @dart_booster_schema NimbleOptions.new!(@dart_booster_params)
  @learning_task_schema NimbleOptions.new!(@learning_task_params)
  @tweedie_schema NimbleOptions.new!(@tweedie_params)
  @pseudohubererror_schema NimbleOptions.new!(@pseudohubererror_params)
  @quantileerror_schema NimbleOptions.new!(@quantileerror_params)
  @survival_schema NimbleOptions.new!(@survival_params)
  @ranking_schema NimbleOptions.new!(@ranking_params)

  @spec validate!(keyword()) :: keyword()
  def validate!(params) when is_list(params) do
    # Get some of the params that other params depend on
    general_params =
      Keyword.take(params, @general_params |> Keyword.keys())
      |> NimbleOptions.validate!(@general_schema)

    booster_params =
      case general_params[:booster] do
        :gbtree ->
          Keyword.take(params, @tree_booster_params |> Keyword.keys())
          |> NimbleOptions.validate!(@tree_booster_schema)

        :gblinear ->
          Keyword.take(params, @linear_booster_params |> Keyword.keys())
          |> NimbleOptions.validate!(@linear_booster_schema)

        :dart ->
          Keyword.take(params, @dart_booster_params |> Keyword.keys())
          |> NimbleOptions.validate!(@dart_booster_schema)
      end

    learning_task_params =
      Keyword.take(params, @learning_task_params |> Keyword.keys())
      |> NimbleOptions.validate!(@learning_task_schema)

    extra_params =
      case learning_task_params[:objective] do
        :reg_tweedie ->
          Keyword.take(params, @tweedie_params |> Keyword.keys())
          |> NimbleOptions.validate!(@tweedie_schema)

        :reg_pseudohubererror ->
          Keyword.take(params, @pseudohubererror_params |> Keyword.keys())
          |> NimbleOptions.validate!(@pseudohubererror_schema)

        :reg_quantileerror ->
          Keyword.take(params, @quantileerror_params |> Keyword.keys())
          |> NimbleOptions.validate!(@quantileerror_schema)

        :survival_aft ->
          Keyword.take(params, @survival_params |> Keyword.keys())
          |> NimbleOptions.validate!(@survival_schema)

        :rank_ndcg ->
          Keyword.take(params, @ranking_params |> Keyword.keys())
          |> NimbleOptions.validate!(@ranking_schema)

        :rank_map ->
          Keyword.take(params, @ranking_params |> Keyword.keys())
          |> NimbleOptions.validate!(@ranking_schema)

        :rank_pairwise ->
          Keyword.take(params, @ranking_params |> Keyword.keys())
          |> NimbleOptions.validate!(@ranking_schema)

        _ ->
          []
      end

    general_params ++ booster_params ++ learning_task_params ++ extra_params
  end
end
