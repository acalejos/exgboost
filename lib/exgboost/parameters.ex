defmodule Exgboost.Parameter do
  alias __MODULE__
  @enforce_keys [:validation]
  defstruct [:reqs, :validation, :default, :alter]

  def parameters do
    %{
      verbosity: %Parameter{
        validation: fn x ->
          case x do
            :silent ->
              0

            :warning ->
              1

            :info ->
              2

            :debug ->
              3

            _ ->
              raise ArgumentError,
                    "Parameter `verbosity` must be in [:silent, :warning, :info, :debug]"
          end
        end
      },
      use_rmm: %Parameter{
        validation: fn x ->
          if x in [true, false],
            do: x,
            else: raise(ArgumentError, "Parameter `use_rmm` must be in [:true, :false]")
        end,
        default: false
      },
      booster: %Parameter{
        validation: fn x ->
          if x in [:gbtree, :gblinear, :dart],
            do: to_string(x),
            else:
              raise(ArgumentError, "Parameter `booster` must be in [:gbtree, :gblinear, :dart]")
        end,
        default: :gbtree
      },
      validate_parameters: %Parameter{
        validation: fn x ->
          if x in [true, false],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `validate_parameters` must be in [:true, :false]"
              )
        end,
        default: true
      },
      nthread: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `nthread` must be >= 0")
        end,
        default: 0
      },
      disable_default_eval_metric: %Parameter{
        validation: fn x ->
          if x in [true, false, 1, 0],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `disable_default_eval_metric` must be in [:true, :false]"
              )
        end,
        default: false
      },
      num_features: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `num_features` must be >= 0")
        end
      },
      eta: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          if(booster)

          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `eta` must be > 0")
        end,
        default: 0.3,
        alter: :learning_rate
      },
      gamma: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `gamma` must be >= 0")
        end,
        default: 0,
        alter: :min_split_loss
      },
      max_depth: %Parameter{
        validation: fn x ->
          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `max_depth` must be > 0")
        end,
        default: 6
      },
      min_child_weight: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `min_child_weight` must be >= 0")
        end,
        default: 1
      },
      max_delta_step: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `max_delta_step` must be >= 0")
        end,
        default: 0
      },
      subsample: %Parameter{
        validation: fn x ->
          if x > 0 and x <= 1,
            do: x,
            else: raise(ArgumentError, "Parameter `subsample` must be in (0, 1]")
        end,
        default: 1,
        alter: :subsample
      },
      colsample_bytree: %Parameter{
        validation: fn x ->
          if x > 0 and x <= 1,
            do: x,
            else: raise(ArgumentError, "Parameter `colsample_bytree` must be in (0, 1]")
        end,
        default: 1
      },
      colsample_bylevel: %Parameter{
        validation: fn x ->
          if x > 0 and x <= 1,
            do: x,
            else: raise(ArgumentError, "Parameter `colsample_bytree` must be in (0, 1]")
        end,
        default: 1
      },
      colsample_bynode: %Parameter{
        validation: fn x ->
          if x > 0 and x <= 1,
            do: x,
            else: raise(ArgumentError, "Parameter `colsample_bytree` must be in (0, 1]")
        end,
        default: 1
      },
      lambda: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `lambda` must be >= 0")
        end,
        default: 1,
        alter: :reg_lambda
      },
      alpha: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `alpha` must be >= 0")
        end,
        default: 0,
        alter: :reg_alpha
      },
      tree_method: %Parameter{
        validation: fn x ->
          if x in [:auto, :exact, :approx, :hist, :gpu_hist],
            do: to_string(x),
            else:
              raise(
                ArgumentError,
                "Parameter `tree_method` must be in [:auto, :exact, :approx, :hist, :gpu_hist]"
              )
        end,
        default: :auto
      },
      scale_pos_weight: %Parameter{
        validation: fn x -> x end,
        default: 1
      },
      updater: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          if booster != :gblinear do
            case x do
              single when not is_list(single) ->
                if single in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh] do
                  single
                else
                  raise(
                    ArgumentError,
                    "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh]"
                  )
                end

              [single] ->
                if single in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh] do
                  single
                else
                  raise(
                    ArgumentError,
                    "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh]"
                  )
                end

              [_head | _tail] ->
                x = Enum.uniq(x)

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
                   do: Enum.map(x, &to_string/1) |> Enum.join(","),
                   else:
                     raise(
                       ArgumentError,
                       "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh]"
                     )

              _ ->
                raise ArgumentError,
                      "Parameter `updater` must only contain [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh]"
            end
          else
            unless x in [:shotgun, :coord_descent] do
              raise(ArgumentError, "Parameter `updater` must be in [:shotgun, :coord_descent]")
            else
              x
            end
          end
        end,
        default: :grow_colmaker
      },
      refresh_leaf: %Parameter{
        validation: fn x ->
          if x in [0, 1],
            do: x,
            else: raise(ArgumentError, "Parameter `refresh_leaf` must either 0 or 1")
        end,
        default: 1
      },
      process_type: %Parameter{
        validation: fn x ->
          if x in [:default, :update],
            do: to_string(x),
            else:
              raise(
                ArgumentError,
                "Parameter `process_type` must be in [:default, :update]"
              )
        end,
        default: :default
      },
      grow_policy: %Parameter{
        reqs: [:tree_method],
        validation: fn x, tree_method ->
          unless tree_method in [:hist, :approx, :gpu_hist] do
            raise(
              ArgumentError,
              "Parameter `grow_policy` is only available for `tree_method: :hist` or `tree_method: :gpu_hist` or `tree_method: :approx`"
            )
          end

          if x in [:depthwise, :lossguide],
            do: to_string(x),
            else:
              raise(
                ArgumentError,
                "Parameter `grow_policy` must be in [:depthwise, :lossguide]"
              )
        end,
        default: :depthwise
      },
      max_leaves: %Parameter{
        validation: fn x ->
          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `max_leaves` must be > 0")
        end,
        default: 0
      },
      max_bin: %Parameter{
        validation: fn x ->
          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `max_bin` must be > 0")
        end,
        default: 256
      },
      predictor: %Parameter{
        validation: fn x ->
          if x in [:auto, :cpu_predictor, :gpu_predictor],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `predictor` must be in [:cpu_predictor, :gpu_predictor]"
              )
        end,
        default: :auto
      },
      num_parallel_tree: %Parameter{
        validation: fn x ->
          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `num_parallel_tree` must be > 0")
        end,
        default: 1
      },
      monotone_constraints: %Parameter{
        validation: fn x ->
          if is_list(x),
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `monotone_constraints` must be a list of monotonic coefficients"
              )
        end,
        default: []
      },
      interaction_constraints: %Parameter{
        validation: fn x ->
          if is_list(x),
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `interaction_constraints` must be a list of interaction constraints"
              )
        end,
        default: []
      },
      multi_strategy: %Parameter{
        validation: fn x ->
          if x in [:one_output_per_tree, :multi_output_tree],
            do: to_string(x),
            else:
              raise(
                ArgumentError,
                "Parameter `multi_strategy` must be in [:one_output_per_tree, :multi_output_tree]"
              )
        end,
        default: :one_output_per_tree
      },
      sample_type: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :gbtree do
            raise(
              ArgumentError,
              "Parameter `sample_type` is only available for `booster: :gbtree`"
            )
          end

          if x in [:uniform, :weighted],
            do: to_string(x),
            else:
              raise(
                ArgumentError,
                "Parameter `sample_type` must be in [:uniform, :weighted]"
              )
        end,
        default: :uniform
      },
      normalize_type: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :gbtree do
            raise(
              ArgumentError,
              "Parameter `normalize_type` is only available for `booster: :gbtree`"
            )
          end

          if x in [:tree, :forest],
            do: to_string(x),
            else:
              raise(
                ArgumentError,
                "Parameter `normalize_type` must be in [:tree, :forest]"
              )
        end,
        default: :tree
      },
      rate_drop: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :dart do
            raise(
              ArgumentError,
              "Parameter `rate_drop` is only available for `booster: :dart`"
            )
          end

          if x >= 0.0 and x <= 1.0,
            do: x,
            else: raise(ArgumentError, "Parameter `rate_drop` must be in range [0, 1]")
        end,
        default: 0.0
      },
      one_drop: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :dart do
            raise(
              ArgumentError,
              "Parameter `one_drop` is only available for `booster: :dart`"
            )
          end

          if x in [0, 1],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `one_drop` must be in [:true, :false]"
              )
        end,
        default: 0
      },
      skip_drop: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :dart do
            raise(
              ArgumentError,
              "Parameter `skip_drop` is only available for `booster: :dart`"
            )
          end

          if x >= 0.0 and x <= 1.0,
            do: x,
            else: raise(ArgumentError, "Parameter `skip_drop` must be in range [0, 1]")
        end,
        default: 0.0
      },
      feature_selector: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :gblinear do
            raise(
              ArgumentError,
              "Parameter `feature_selector` is only available for `booster: :gblinear`"
            )
          end

          if x in [:cyclic, :shuffle, :random, :greedy, :thrifty],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `feature_selector` must be in [:cyclic, :shuffle, :random, :greedy, :thrifty]"
              )
        end,
        default: :cyclic
      },
      top_k: %Parameter{
        reqs: [:booster],
        validation: fn x, booster ->
          unless booster == :gblinear do
            raise(
              ArgumentError,
              "Parameter `top_k` is only available for `booster: :gblinear`"
            )
          end

          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `top_k` must be > 0")
        end,
        default: 0
      },
      objective: %Parameter{
        validation: fn x ->
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
            do: Atom.to_string(x) |> String.replace("_", ":"),
            else:
              raise(
                ArgumentError,
                "Parameter `objective` must be in [:reg_squarederror, :reg_squaredlogerror, :reg_logistic, :reg_pseudohubererror, :reg_absoluteerror, :reg_quantileerror, :binary_logistic, :binary_logitraw, :binary_hinge, :count_poisson, :survival_cox, :survival_aft, :multi_softmax, :multi_softprob, :rank_ndcg, :rank_map, :rank_pairwise, :reg_gamma, :reg_tweedie])"
              )
          )
        end,
        default: :reg_squarederror
      },
      base_score: %Parameter{
        validation: fn x -> x end
      },
      eval_metric: %Parameter{
        validation: fn x ->
          x = if is_list(x), do: x, else: [x]

          Enum.each(x, fn y ->
            cond do
              String.contains?(y, "@") or String.ends_with?(y, "-") ->
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
                raise(
                  ArgumentError,
                  "Parameter `eval_metric` must be in [:rmse, :mae, :logloss, :error, :error, :merror, :mlogloss, :auc, :aucpr, :ndcg, :map, :ndcg, :map, :ndcg, :map, :poisson_nloglik, :gamma_nloglik, :gamma_deviance, :tweedie_nloglik, :tweedie_deviance], found #{inspect(y)}"
                )
            end
          end)
        end,
        default: []
      },
      seed: %Parameter{
        validation: fn x ->
          if x >= 0,
            do: x,
            else: raise(ArgumentError, "Parameter `seed` must be >= 0")
        end,
        default: 0
      },
      seed_per_iteration: %Parameter{
        validation: fn x ->
          if x in [true, false],
            do: x,
            else:
              raise(ArgumentError, "Parameter `seed_per_iteration` must be in [:true, :false]")
        end,
        default: false
      },
      tweedie_variance_power: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective == :reg_tweedie do
            raise(
              ArgumentError,
              "Parameter `tweedie_variance_power` is only available for `objective: :reg_tweedie`"
            )
          end

          if x > 1 and x < 2,
            do: x,
            else: raise(ArgumentError, "Parameter `tweedie_variance_power` must be in (1, 2)")
        end,
        default: 1.5
      },
      huber_slope: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective == :reg_pseudohubererror do
            raise(
              ArgumentError,
              "Parameter `huber_slope` is only available for `objective: :reg_pseudohubererror`"
            )
          end

          if x > 0,
            do: x,
            else: raise(ArgumentError, "Parameter `huber_slope` must be > 0")
        end,
        default: 1.0
      },
      quantile_alpha: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective == :reg_quantileerror do
            raise(
              ArgumentError,
              "Parameter `quantile_alpha` is only available for `objective: :reg_quantileerror`"
            )
          end

          if x > 0 and x < 1,
            do: x,
            else: raise(ArgumentError, "Parameter `quantile_alpha` must be in (0, 1)")
        end,
        default: 0.5
      },
      aft_loss_distribution: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective == :survival_aft do
            raise(
              ArgumentError,
              "Parameter `aft_loss_distribution` is only available for `objective: :survival_aft`"
            )
          end

          if x in [:normal, :logistic, :extreme],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `aft_loss_distribution` must be in [:normal, :logistic, :extreme]"
              )
        end,
        default: :normal
      },
      lambdarank_pair_method: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective in [:rank_pairwise, :rank_ndcg, :rank_map] do
            raise(
              ArgumentError,
              "Parameter `lambdarank_pair_method` is only available for `objective in in [:rank_pairwise, :rank_ndcg, :rank_map]`"
            )
          end

          if x in [:mean, :topk],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `lambdarank_pair_method` must be in [:mean, :topk]"
              )
        end,
        default: :mean
      },
      lambdarank_num_pair_per_sample: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective in [:rank_pairwise, :rank_ndcg, :rank_map] do
            raise(
              ArgumentError,
              "Parameter `lambdarank_num_pair_per_sample` is only available for `objective in in [:rank_pairwise, :rank_ndcg, :rank_map]`"
            )
          end

          if x >= 1,
            do: x,
            else: raise(ArgumentError, "Parameter `lambdarank_num_pair_per_sample` must be > 0")
        end,
        default: 1
      },
      lambdarank_unbiased: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective in [:rank_pairwise, :rank_ndcg, :rank_map] do
            raise(
              ArgumentError,
              "Parameter `lambdarank_unbiased` is only available for `objective in in [:rank_pairwise, :rank_ndcg, :rank_map]`"
            )
          end

          if x in [true, false],
            do: x,
            else:
              raise(
                ArgumentError,
                "Parameter `lambdarank_unbiased` must be in [:true, :false]"
              )
        end,
        default: false
      },
      lambdarank_bias_norm: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective in [:rank_pairwise, :rank_ndcg, :rank_map] do
            raise(
              ArgumentError,
              "Parameter `lambdarank_bias_norm` is only available for `objective in in [:rank_pairwise, :rank_ndcg, :rank_map]`"
            )
          end

          if x in [:l1, :l2],
            do: if(x == :l1, do: 1.0, else: 2.0),
            else:
              raise(
                ArgumentError,
                "Parameter `lambdarank_bias_norm` must be in [:l1, :l2]"
              )
        end,
        default: :l2
      },
      ndcg_exp_gain: %Parameter{
        reqs: [:objective],
        validation: fn x, objective ->
          unless objective in [:rank_ndcg, :rank_map, :rank_pairwise] do
            raise(
              ArgumentError,
              "Parameter `ndcg_exp_gain` is only available for `objective in in [:rank_ndcg, :rank_map, :rank_pairwise]`"
            )
          end

          if x in [true, false],
            do: x,
            else: raise(ArgumentError, "Parameter `ndcg_exp_gain` must be in [true, false]")
        end,
        default: true
      }
    }
  end
end
