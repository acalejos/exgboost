defmodule EXGBoost.Parameters do
  import Exterval

  @global_params [
    verbosity: [
      type: {:custom, EXGBoost.Parameters, :validate_verbosity, []},
      default: :silent,
      doc: """
      Verbosity of printing messages. Valid values are:
      `:silent`, `:warning`, `:info`, `:debug`.
      """
    ],
    use_rmm: [
      type: :boolean,
      default: false,
      doc: """
      Whether to use RAPIDS Memory Manager for memory allocation.
      This option is only applicable when XGBoost is built (compiled)
      with the RMM plugin enabled. Valid values are `true` and `false`.
      """
    ]
  ]

  @general_params [
    booster: [
      type: {:in, [:gbtree, :gblinear, :dart]},
      default: :gbtree,
      doc: """
      Which booster to use. Valid values are `:gbtree`, `:gblinear`, `:dart`
        * `:gbtree` - tree-based models
        * `:gblinear` - linear models
        * `:dart` - tree-based models with dropouts
      """
    ],
    device: [
      type: {:custom, EXGBoost.Parameters, :validate_device, []},
      default: :cpu,
      doc: """
      Device for XGBoost to run. User can set it to one of the following values:
        * `:cpu` - Use a CPU.
        * `:cuda` - Use a GPU (CUDA device).
        * `{:cuda, ordinal}` -  `ordinal` is an integer that specifies the ordinal of the GPU (which GPU do you want to use if you have more than one devices).
        * `:gpu` - Default GPU device selection from the list of available and supported devices. Only `cuda` devices are supported currently.
        * `{:gpu, ordinal}` - Default GPU device selection from the list of available and supported devices. Only `cuda` devices are supported currently.

        For more information about GPU acceleration, see [XGBoost GPU Support](https://xgboost.readthedocs.io/en/stable/gpu/index.html). In distributed environments, ordinal selection is handled by distributed frameworks instead of XGBoost. As a result, using `{:cuda, ordinal}` will result in an error. Use `:cuda` instead.
      """
    ],
    verbosity: [
      type: {:custom, EXGBoost.Parameters, :validate_verbosity, []},
      default: :silent,
      doc: """
      Verbosity of printing messages. Valid values are:
      `:silent`, `:warning`, `:info`, `:debug`
      """
    ],
    validate_parameters: [
      type: :boolean,
      default: true,
      doc: """
      Whether to perform validation of parameters. If set to `true`, an error
      will be raised if an invalid parameter is passed to the booster, and
      EXGBoost will take care of formatting all parameters to the expected
      input of XGBoost. If set to `false`, the user is responsible for ensuring
      that all parameters are valid strings which is what XGBoost is expecting.
      """
    ],
    nthread: [
      type: :non_neg_integer,
      default: Application.compile_env(:exgboost, :nthread, 0),
      doc: """
      Number of threads to use for training and prediction. If `0`, then the
      number of threads is set to the number of cores.  This can be set globally
      using the `:exgboost` application environment variable `:nthread`
      or on a per booster basis.  If set globally, the value will be used for
      all boosters unless overridden by a specific booster.
      To set the number of threads globally, add the following to your `config.exs`:
      `config :exgboost, nthread: n`.
      """
    ],
    disable_default_eval_metric: [
      type: :boolean,
      default: false,
      doc: """
      Whether to disable the default metric. If set to `true`, then the default
      metric is not used for evaluation. This is useful when using custom
      evaluation metrics.
      """
    ],
    num_features: [
      type: :non_neg_integer,
      doc: """
      Feature dimension used in boosting, set to maximum dimension of the feature
      """
    ]
  ]

  @tree_booster_params [
    eta: [
      type: {:in, ~i<[0,1]>},
      default: 0.3,
      doc: """
      Step size shrinkage used in update to prevents overfitting. After each
      boosting step, we can directly get the weights of new features. and `eta`
      actually shrinks the feature weights to make the boosting process more
      conservative. Valid range is [0,1].
      """
    ],
    gamma: [
      type: {:in, ~i<[0,:infinity]>},
      default: 0.0,
      doc: ~S"""
      Minimum loss reduction required to make a further partition on a leaf node
      of the tree. The larger `gamma` is, the more conservative the algorithm will
      be. Valid range is [0, $\infty$].
      """
    ],
    max_depth: [
      type: :non_neg_integer,
      default: 6,
      doc: """
      Maximum depth of a tree. Increasing this value will make the model more complex
      and more likely to overfit. `0` indicates no limit on depth. Beware that XGBoost
      aggressively consumes memory when training a deep tree. `exact` tree method requires
      non-zero value.
      """
    ],
    min_child_weight: [
      type: {:in, ~i<[0,:infinity]>},
      default: 1,
      doc: ~S"""
      Minimum sum of instance weight (hessian) needed in a child. If the tree partition
      step results in a leaf node with the sum of instance weight less than `min_child_weight`,
      then the building process will give up further partitioning. In linear regression task,
      this simply corresponds to minimum number of instances needed to be in each node.
      The larger `min_child_weight` is, the more conservative the algorithm will be.
      Valid range is [0, $\infty$].
      """
    ],
    max_delta_step: [
      type: {:in, ~i<[0,:infinity]>},
      default: 0,
      doc: ~S"""
      Maximum delta step we allow each tree's weight estimation to be. If the value is set
      to `0`, it means there is no constraint. If it is set to a positive value, it can help
      making the update step more conservative. Usually this parameter is not needed, but it
      might help in logistic regression when class is extremely imbalanced. Set it to value of
      1-10 might help control the update. Valid range is [0, $\infty$].
      """
    ],
    subsample: [
      type: {:in, ~i<(0,1]>},
      default: 1.0,
      doc: """
      Subsample ratio of the training instance. Setting it to `0.5` means that XGBoost
      randomly collected half of the data instances to grow trees and this will prevent
      overfitting. Subsampling will occur once in every boosting iteration. Valid range is (0, 1].
      """
    ],
    sampling_method: [
      type: {:in, [:uniform]},
      default: :uniform,
      doc: ~S"""
      The method to use to sample the training instances.
        * `:uniform` - each training instance has an equal probability of being selected.
          Typically set `:subsample` $\ge$ 0.5 for good results.
      """
    ],
    colsample_by: [
      type: {:custom, EXGBoost.Parameters, :validate_colsample, []},
      doc: """
      This is a family of parameters for subsampling of columns.
      All `colsample_by` parameters have a range of `(0, 1]`, the default value of `1`, and specify the fraction of columns to be subsampled.
      `colsample_by` parameters work cumulatively. For instance, the combination
      `col_sampleby: [tree: 0.5, level: 0.5, node: 0.5]` with `64` features will leave `8`.
        * `:tree` - The subsample ratio of columns when constructing each tree. Subsampling occurs once for every tree constructed. Valid range is (0, 1]. The default value is `1`.
        * `:level` - The subsample ratio of columns for each level. Subsampling occurs once for every new depth level reached in a tree. Columns are subsampled from the set of columns chosen for the current tree. Valid range is (0, 1]. The default value is `1`.
        * `:node` - The subsample ratio of columns for each node (split). Subsampling occurs once every time a new split is evaluated. Columns are subsampled from the set of columns chosen for the current level. Valid range is (0, 1]. The default value is `1`.
      """
    ],
    lambda: [
      type: {:in, ~i<[0,:infinity]>},
      default: 1,
      doc: ~S"""
      L2 regularization term on weights. Increasing this value will make model more conservative.
      Valid range is [0, $\infty$].
      """
    ],
    alpha: [
      type: {:in, ~i<[0,:infinity]>},
      default: 0,
      doc: ~S"""
      L1 regularization term on weights. Increasing this value will make model more conservative.
      Valid range is [0, $\infty$].
      """
    ],
    tree_method: [
      type: {:in, [:auto, :exact, :approx, :hist]},
      default: :auto,
      doc: """
      The tree construction algorithm used in XGBoost.
      This is a combination of commonly used updaters. For other updaters like
      `refresh`, set the parameter `updater` directly.
        * `:auto` - Use heuristic to choose the fastest method.
          * For small dataset, exact greedy (`exact`) will be used.
          * For larger dataset, approximate algorithm (`approx`) will be chosen. It’s recommended to try
            `hist` for higher performance with large dataset.
          * Because old behavior is always use exact greedy in single machine, user will get a message
            when approximate algorithm is chosen to notify this choice.
        * `:exact` - Exact greedy algorithm. Enumerates all split candidates.
        * `:approx` - Approximate greedy algorithm using sketching and histogram.
        * `:hist` - Faster histogram optimized approximate greedy algorithm.
      """
    ],
    scale_pos_weight: [
      type: :float,
      default: 1.0,
      doc: """
      Control the balance of positive and negative weights, useful for unbalanced classes.
      A typical value to consider: `sum(negative instances) / sum(positive instances)`.
      """
    ],
    updater: [
      type: {:custom, EXGBoost.Parameters, :validate_tree_updater, []},
      doc: """
      A list defining the sequence of tree updaters to run, providing a
      modular way to construct and to modify the trees. This is an advanced parameter that
      is usually set automatically, depending on some other parameters. However, it could be
      also set explicitly by a user. The following updaters exist:
        * `:grow_colmaker` - non-distributed column-based construction of trees.
        * `:grow_histmaker` - distributed tree construction with row-based data splitting based on global proposal of histogram counting.
        * `:grow_quantile_histmaker` - Grow tree using quantized histogram.
        * `:sync` - synchronizes trees in all distributed nodes.
        * `:refresh` - refreshes tree’s statistics and/or leaf values based on the current data. Note that no random subsampling of data rows is performed.
        * `:prune` - prunes the splits where loss < min_split_loss (or gamma) and nodes that have depth greater than max_depth.
      """
    ],
    refresh_leaf: [
      type: {:in, [0, 1]},
      default: 1,
      doc: """
      This is a parameter of the refresh updater. When this flag is 1,
      tree leafs as well as tree nodes’ stats are updated. When it is 0, only node stats are updated.
      """
    ],
    process_type: [
      type: {:in, [:default, :update]},
      default: :default,
      doc: """
      The type of boosting process to run
        * `:default` - The normal boosting process which creates new trees.
        * `:update` - Starts from an existing model and only updates its trees. In each boosting iteration,
            a tree from the initial model is taken, a specified sequence of updaters is run for that tree,
            and a modified tree is added to the new model. The new model would have either the same or
            smaller number of trees, depending on the number of boosting iterations performed. Currently,
            the following built-in updaters could be meaningfully used with this process type:
            `refresh`, `prune`. With `process_type: update`, one cannot use updaters that create new trees.
      """
    ],
    grow_policy: [
      type: {:in, [:depthwise, :lossguide]},
      default: :depthwise,
      doc: """
      Controls a way new nodes are added to the tree. Currently supported only if `tree_method` is set
      to `:hist` or `:approx`.
        * `:depthwise` - split at nodes closest to the root.
        * `:lossguide` - split at nodes with highest loss change.
      """
    ],
    max_leaves: [
      type: :non_neg_integer,
      default: 0,
      doc: """
      Maximum number of nodes to be added. Not used by `exact` tree method.
      """
    ],
    max_bin: [
      type: :pos_integer,
      default: 256,
      doc: """
      Maximum number of discrete bins to bucket continuous features. Used only if
      `tree_method` is set to `:hist` or `:approx`.
      Maximum number of discrete bins to bucket continuous features.
      Increasing this number improves the optimality of splits at the cost of higher computation time.
      """
    ],
    predictor: [
      type: {:in, [:auto, :cpu_predictor]},
      default: :auto,
      doc: """
      The type of predictor algorithm to use. Provides the same results but allows the use of GPU or CPU.
        * `:auto` - Configure predictor based on heuristics.
        * `:cpu_predictor` - Multicore CPU prediction algorithm.
      """
    ],
    num_parallel_tree: [
      type: :non_neg_integer,
      default: 1,
      doc: """
      Number of parallel trees constructed during each iteration. This option is used to support boosted random forest.
      """
    ],
    monotone_constraints: [
      type: {:list, {:or, [:float, :integer]}},
      doc: """
      Constraint of variable monotonicity. See [Monotonic Constraints](https://xgboost.readthedocs.io/en/latest/tutorials/monotonic.html) for more information.
      """
    ],
    interaction_constraints: [
      type: {:list, {:list, :integer}},
      doc: """
      Constraints for interaction representing permitted interactions. The constraints must be specified in the
      form of a nested list, e.g. `[[0, 1], [2, 3, 4]]`, where each inner list is a group of indices of features
      that are allowed to interact with each other. See [Feature Interaction Constraints](https://xgboost.readthedocs.io/en/latest/tutorials/feature_interaction_constraint.html) for more information.
      """
    ],
    multi_strategy: [
      type: {:in, [:one_output_per_tree, :multi_output_tree]},
      default: :one_output_per_tree,
      doc: """
      The strategy used for training multi-target models, including multi-target regression and multi-class
      classification. See [Multiple Outputs](https://xgboost.readthedocs.io/en/latest/tutorials/multioutput.html) for more information.
        * `:one_output_per_tree` - One model for each target.
        * `:multi_output_tree` - Use multi-target trees.
      """
    ],
    max_cached_hist_node: [
      type: :non_neg_integer,
      default: 65536,
      doc: """
      Maximum number of cached nodes for CPU histogram. For most of the cases this parameter should not be set except for growing deep trees on CPU.
      """
    ]
  ]

  @dart_booster_params @tree_booster_params ++
                         [
                           sample_type: [
                             type: {:in, [:uniform, :weighted]},
                             default: :uniform,
                             doc: """
                             Type of sampling algorithm.
                                * `:uniform` - Dropped trees are selected uniformly.
                                * `:weighted` - Dropped trees are selected in proportion to weight.
                             """
                           ],
                           normalize_type: [
                             type: {:in, [:tree, :forest]},
                             default: :tree,
                             doc: """
                             Type of normalization algorithm.
                                * `:tree` - New trees have the same weight of each of dropped trees.
                                    * Weight of new trees are `1 / (k + learning_rate)`.
                                    * Dropped trees are scaled by a factor of `k / (k + learning_rate)`.
                                * `:forest` - New trees have the same weight of sum of dropped trees (forest).
                                    * Weight of new trees are 1 / (1 + learning_rate).
                                    * Dropped trees are scaled by a factor of 1 / (1 + learning_rate).
                             """
                           ],
                           rate_drop: [
                             type: {:in, ~i<[0,1]>},
                             default: 0.0,
                             doc: """
                             Dropout rate (a fraction of previous trees to drop during the dropout). Valid range is [0, 1].
                             """
                           ],
                           one_drop: [
                             type: {:in, [0, 1]},
                             default: 0,
                             doc: """
                             When this flag is enabled, at least one tree is always dropped during the dropout (allows Binomial-plus-one or epsilon-dropout from the original DART paper).
                             """
                           ],
                           skip_drop: [
                             type: {:in, ~i<[0,1]>},
                             default: 0.0,
                             doc: """
                             Probability of skipping the dropout procedure during a boosting iteration. Valid range is [0, 1].
                                * If a dropout is skipped, new trees are added in the same manner as gbtree.
                                * **Note** that non-zero skip_drop has higher priority than rate_drop or one_drop.
                             """
                           ]
                         ]

  @linear_booster_params [
    lambda: [
      type: :float,
      default: 0.0,
      doc: """
      L2 regularization term on weights. Increasing this value will make model more conservative. Normalised to number of training examples.
      """
    ],
    alpha: [
      type: :float,
      default: 0.0,
      doc: """
      L1 regularization term on weights. Increasing this value will make model more conservative. Normalised to number of training examples.
      """
    ],
    updater: [
      type: {:in, [:shotgun, :coord_descent]},
      default: :shotgun,
      doc: """
      Choice of algorithm to fit linear model
        * `:shotgun` - Parallel coordinate descent algorithm based on shotgun algorithm. Uses ‘hogwild’ parallelism and therefore produces a nondeterministic solution on each run.
        * `:coord_descent` - Ordinary coordinate descent algorithm. Also multithreaded but still produces a deterministic solution.
      """
    ],
    feature_selector: [
      type: {:in, [:cyclic, :shuffle, :random, :greedy, :thrifty]},
      default: :cyclic,
      doc: ~S"""
      Feature selection and ordering method
        * `:cyclic` - Deterministic selection by cycling through features one at a time. Used with the `:shotgun` updater.
        * `:shuffle` - Similar to `:cyclic` but with random feature shuffling prior to each update. Used with the `:shotgun` updater.
        * `:random` - A random (with replacement) coordinate selector. Used with the `:coord_descent` updater.
        * `:greedy` - Select coordinate with the greatest gradient magnitude. It has $O(num_feature^2)$ complexity. It is fully deterministic. It allows restricting the selection to `:top_k` features per group with the largest magnitude of univariate weight change, by setting the `:top_k` parameter. Doing so would reduce the complexity to $O(num_feature^{topk})$. Used by `:coord_descent` updater.
        * `:thrifty` - Thrifty, approximately-greedy feature selector. Prior to cyclic updates, reorders features in descending magnitude of their univariate weight changes. This operation is multithreaded and is a linear complexity approximation of the quadratic greedy selection. It allows restricting the selection to `:top_k` features per group with the largest magnitude of univariate weight change, by setting the `:top_k` parameter. Used by `:coord_descent` updater.
      """
    ],
    top_k: [
      type: :non_neg_integer,
      default: 0,
      doc: """
      The number of top features to select in `:greedy` and `:thrifty` feature selector. The value of 0 means using all the features.
      """
    ]
  ]

  @learning_task_params [
    objective: [
      type: {:custom, EXGBoost.Parameters, :validate_objective, []},
      default: :reg_squarederror,
      doc: ~S"""
      Specify the learning task and the corresponding learning objective. The objective options are:
        * `:reg_squarederror` - regression with squared loss.
        * `:reg_squaredlogerror` - regression with squared log loss $\frac{1}{2}[\log (pred + 1) - \log (label + 1)]^2$. All input labels are required to be greater than `-1`. Also, see metric rmsle for possible issue with this objective.
        * `:reg_logistic` - logistic regression.
        * `:reg_pseudohubererror` - regression with Pseudo Huber loss, a twice differentiable alternative to absolute loss.
        * `:reg_absoluteerror` - Regression with `L1` error. When tree model is used, leaf value is refreshed after tree construction. If used in distributed training, the leaf value is calculated as the mean value from all workers, which is not guaranteed to be optimal.
        * `:reg_quantileerror` - Quantile loss, also known as pinball loss. See later sections for its parameter and Quantile Regression for a worked example.
        * `:binary_logistic` - logistic regression for binary classification, output probability
        * `:binary_logitraw` - logistic regression for binary classification, output score before logistic transformation
        * `:binary_hinge` - hinge loss for binary classification. This makes predictions of `0` or `1`, rather than producing probabilities.
        * `:count_poisson` - Poisson regression for count data, output mean of Poisson distribution.
            * `max_delta_step` is set to `0.7` by default in Poisson regression (used to safeguard optimization)
        * `:survival_cox` - Cox regression for right censored survival time data (negative values are considered right censored). Note that predictions are returned on the hazard ratio scale (i.e., as `HR = exp(marginal_prediction)` in the proportional hazard function `h(t) = h0(t) * HR`).
        * `:survival_aft` - Accelerated failure time model for censored survival time data. See [Survival Analysis with Accelerated Failure Time](https://xgboost.readthedocs.io/en/latest/tutorials/aft_survival_analysis.html) for details.
        * `:multi_softmax` - set XGBoost to do multiclass classification using the softmax objective, you also need to set num_class(number of classes)
        * `:multi_softprob` - same as softmax, but output a vector of ndata * nclass, which can be further reshaped to ndata * nclass matrix. The result contains predicted probability of each data point belonging to each class.
        * `:rank_ndcg` - Use LambdaMART to perform pair-wise ranking where Normalized Discounted Cumulative Gain (NDCG) is maximized. This objective supports position debiasing for click data.
        * `:rank_map` - Use LambdaMART to perform pair-wise ranking where Mean Average Precision (MAP) is maximized
        * `:rank_pairwise` - Use LambdaRank to perform pair-wise ranking using the ranknet objective.
        * `:reg_gamma` - gamma regression with log-link. Output is a mean of gamma distribution. It might be useful, e.g., for modeling insurance claims severity, or for any outcome that might be gamma-distributed.
        * `:reg_tweedie` - Tweedie regression with log-link. It might be useful, e.g., for modeling total loss in insurance, or for any outcome that might be Tweedie-distributed.
      """
    ],
    base_score: [
      type: :float,
      doc: """
      The initial prediction score of all instances, global bias
      The parameter is automatically estimated for selected objectives before training. To disable the estimation, specify a real number argument.
      For sufficient number of iterations, changing this value will not have too much effect.
      """
    ],
    eval_metric: [
      type: {:custom, EXGBoost.Parameters, :validate_eval_metric, []},
      doc: """
      Evaluation metrics for validation data, a default metric will be assigned according to objective (`:rmse` for regression, and `:logloss` for classification, `mean average precision` for `:rank_map`, etc.)
      User can add multiple evaluation metrics.
        * `:rmse` - root mean square error
        * `:rmsle` - root mean square log error. Default metric of `:reg_squaredlogerror` objective. This metric reduces errors generated by outliers in dataset. But because `log` function is employed, `:rmsle` might output nan when prediction value is less than `-1`. See `:reg_squaredlogerror` for other requirements.
        * `:mae` - mean absolute error
        * `:mape` - mean absolute percentage error
        * `:mphe` - mean Pseudo Huber error. Default metric of `:reg_pseudohubererror` objective.
        * `:logloss` - negative log-likelihood
        * `:error` - Binary classification error rate. It is calculated as `#(wrong cases)/#(all cases)`. For the predictions, the evaluation will regard the instances with prediction value larger than `0.5` as positive instances, and the others as negative instances.
        * `{:error,t}` - a different than `0.5` binary classification threshold value could be specified by providing a numerical value through `t`.
        * `:merror` - Multiclass classification error rate. It is calculated as `#(wrong cases)/#(all cases)`.
        * `:mlogloss` - Multiclass logloss.
        * `:auc` - Receiver Operating Characteristic Area under the Curve. Available for classification and learning-to-rank tasks.
          * When used with binary classification, the objective should be `:binary_logistic` or similar functions that work on probability.
          * When used with multi-class classification, objective should be `:multi_softprob` instead of `:multi_softmax`, as the latter doesn’t output probability. Also the AUC is calculated by 1-vs-rest with reference class weighted by class prevalence.
          * When used with LTR task, the AUC is computed by comparing pairs of documents to count correctly sorted pairs. This corresponds to pairwise learning to rank. The implementation has some issues with average AUC around groups and distributed workers not being well-defined.
          * On a single machine the AUC calculation is exact. In a distributed environment the AUC is a weighted average over the AUC of training rows on each node - therefore, distributed AUC is an approximation sensitive to the distribution of data across workers. Use another metric in distributed environments if precision and reproducibility are important.
          * When input dataset contains only negative or positive samples, the output is NaN. The behavior is implementation defined, for instance, scikit-learn returns  instead.
        * `:aucpr` - Area under the PR curve. Available for classification and learning-to-rank tasks.
        * `:ndcg` - Normalized Discounted Cumulative Gain
        * `:map` - Mean Average Precision
        * `{:ndcg,n}`, `{:map,n}` - `n` can be assigned as an integer to cut off the top positions in the lists for evaluation.
        * `:inv_ndcg`, `:inv_map`, `{:inv_ndcg, n}`, `{:inv_map, n}` - In XGBoost, the NDCG and MAP evaluate the score of a list without any positive samples as `1`. By using the `:inv_` variant, we can ask XGBoost to evaluate these scores as `0` to be consistent under some conditions.
        * `:poisson_nloglik` - negative log-likelihood for Poisson regression
        * `:gamma_nloglik` - negative log-likelihood for gamma regression
        * `:cox_nloglik` - negative partial log-likelihood for Cox proportional hazards regression
        * `:gamma_deviance` - residual deviance for gamma regression
        * `:tweedie_nloglik` - negative log-likelihood for Tweedie regression (at a specified value of the `:tweedie_variance_power` parameter). Must provide `:tweedie_variance_power` parameter.
        * `{:tweedie_nloglik, rho}` - negative log-likelihood for Tweedie regression with `rho` denoting the `:tweedie_variance_power` parameter.
        * `:aft_nloglik` - Negative log likelihood of Accelerated Failure Time model. See Survival Analysis with Accelerated Failure Time for details.
        * `:interval_regression_accuracy` - Fraction of data points whose predicted labels fall in the interval-censored labels. Only applicable for interval-censored data. See Survival Analysis with Accelerated Failure Time for details.
      """
    ],
    seed: [
      type: :non_neg_integer,
      default: 0,
      doc: """
      Random number seed.
      """
    ],
    set_seed_per_iteration: [
      type: :boolean,
      default: false,
      doc: """
      Seed PRNG determnisticly via iterator number.
      """
    ]
  ]

  @tweedie_params [
    tweedie_variance_power: [
      type: {:in, ~i<(1,2)>},
      default: 1.5,
      doc: """
      Parameter that controls the variance of the Tweedie distribution `var(y) ~ E(y)^tweedie_variance_power`.
      Valid range is (1,2).
      Set closer to 2 to shift towards a gamma distribution.
      Set closer to 1 to shift towards a Poisson distribution.
      """
    ]
  ]

  @pseudohubererror_params [
    huber_slope: [
      type: {:in, ~i<[0,:infinity]>},
      default: 1.0,
      doc: """
      A parameter used for Pseudo-Huber loss.
      """
    ]
  ]

  @multi_soft_params [
    num_class: [
      type: :pos_integer,
      doc: """
      Number of classes.
      """
    ]
  ]

  @quantileerror_params [
    quantile_alpha: [
      type: {:in, ~i<(0,1)>},
      default: 0.5,
      doc: """
      Targeted Quantile.
      """
    ]
  ]

  @survival_params [
    aft_loss_distribution: [
      type: {:in, [:normal, :logistic, :extreme]},
      default: :normal,
      doc: """
      Probability Density Function, `:normal`, `:logistic`, or `:extreme`.
      """
    ]
  ]

  @ranking_params [
    lambdarank_pair_method: [
      type: {:in, [:mean, :topk]},
      default: :mean,
      doc: """
      How to construct pairs for pair-wise learning.
        * `:mean` - Sample `lambdarank_num_pair_per_sample` pairs for each document in the query list.
        * `:topk` - Focus on top-`lambdarank_num_pair_per_sample` documents. Construct pairs for each document at the top-`lambdarank_num_pair_per_sample` ranked by the model.
      """
    ],
    lambdarank_num_pair_per_sample: [
      type: {:in, ~i<[1,:infinity]>},
      doc: ~S"""
           It specifies the number of pairs sampled for each document when pair method is `:mean`, or the truncation level for queries when the pair method is `:topk`. For example, to train with `{:ndcg,6}`, set `:lambdarank_num_pair_per_sample` to `6` and `:lambdarank_pair_method` to `topk`. Valid range is [1, $\infty$].
      """
    ],
    lambdarank_unbiased: [
      type: :boolean,
      default: false,
      doc: """
      Specify whether do we need to debias input click data.
      """
    ],
    lambdarank_bias_norm: [
      type: {:in, [1.0, 2.0]},
      default: 2.0,
      doc: """
      LP normalization for position debiasing, default is L2.
      Only relevant when lambdarank_unbiased is set to true.
      """
    ],
    ndcg_exp_gain: [
      type: :boolean,
      default: true,
      doc: """
        Whether we should use exponential gain function for `NDCG`. There are two forms of gain function for `NDCG`,
        one is using relevance value directly while the other is using `2^rel -1` to emphasize on retrieving
        relevant documents. When `:ndcg_exp_gain` is `true` (the default), relevance degree cannot be greater than `31`.
      """
    ]
  ]

  @doc false
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

  def validate_device(x) do
    case x do
      {device, ordinal}
      when device in [:cuda, :gpu] and is_integer(ordinal) and ordinal >= 0 ->
        {:ok, "#{device}:#{ordinal}"}

      device when device in [:cpu, :gpu, :cuda] ->
        {:ok, Atom.to_string(device)}

      _ ->
        {:error,
         "Parameter `device` must be in [:cpu, :gpu, :cuda, {:cuda, device}, {:gpu, device}], got #{inspect(x)}"}
    end
  end

  @doc false
  def validate_colsample(x) do
    unless is_list(x) do
      {:error, "Parameter `colsample` must be a list, got #{inspect(x)}"}
    else
      Enum.reduce_while(x, {:ok, []}, fn x, {_status, acc} ->
        case x do
          {key, value} when key in [:tree, :level, :node] and is_number(value) ->
            if value in ~i<(0,1]> do
              {:cont, {:ok, [{String.to_atom("colsample_by#{key}"), value} | acc]}}
            else
              {:halt, {:error, "Parameter `colsample` must be in (0,1], got #{inspect(x)}"}}
            end

          {key, _value} ->
            {:halt,
             {:error,
              "Parameter `colsample` must be in [:tree, :level, :node], got #{inspect(key)}"}}

          _ ->
            {:halt, {:error, "Parameter `colsample` must be a keyword list, got #{inspect(x)}"}}
        end
      end)
    end
  end

  @doc false
  def validate_eval_metric(x) do
    x = if is_list(x), do: x, else: [x]

    metrics =
      Enum.map(x, fn y ->
        case y do
          {task, n} when task in [:error, :ndcg, :map, :tweedie_nloglik] and is_number(n) ->
            task = Atom.to_string(task) |> String.replace("_", "-")
            "#{task}@#{n}"

          {task, n} when task in [:inv_ndcg, :inv_map] and is_number(n) ->
            [task | _tail] = task |> Atom.to_string() |> String.split("_") |> Enum.reverse()
            "#{task}@#{n}-"

          task when task in [:inv_ndcg, :inv_map] ->
            [task | _tail] = task |> Atom.to_string() |> String.split("_") |> Enum.reverse()
            "#{task}-"

          task
          when task in [
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
                 :tweedie_nloglik,
                 :poisson_nloglik,
                 :gamma_nloglik,
                 :cox_nloglik,
                 :gamma_deviance,
                 :aft_nloglik,
                 :interval_regression_accuracy
               ] ->
            Atom.to_string(task) |> String.replace("_", "-")

          _ ->
            raise ArgumentError,
                  "Parameter `eval_metric` must be in [:rmse, :mae, :logloss, :error, :error, :merror, :mlogloss, :auc, :aucpr, :ndcg, :map, :ndcg, :map, :ndcg, :map, :poisson_nloglik, :gamma_nloglik, :gamma_deviance, :tweedie_nloglik, :tweedie_deviance], got #{inspect(y)}"
        end
      end)

    {:ok, metrics}
  end

  @doc false
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

  @doc false
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

  @doc false
  def validate_tree_updater(single) when is_atom(single) do
    if single in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh] do
      {:ok, single}
    else
      {:error,
       "Parameter `updater` must only contain values in [:grow_colmaker, :prune, :refresh, :grow_histmaker, :sync, :refresh], got #{inspect(single)}"}
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
  @multi_soft_schema NimbleOptions.new!(@multi_soft_params)

  @moduledoc """
  Parameters are used to configure the training process and the booster.

  ## Global Parameters

  You can set the following params either using a global application config (preferred)
  or using the `EXGBoost.set_config/1` function. The global config is set using the `:exgboost` key.
  Note that using the `EXGBoost.set_config/1` function will override the global config for the
  current instance of the application.

  ```elixir
  config :exgboost,
    verbosity: :info,
    use_rmm: true,
  ```
  #{NimbleOptions.docs(@global_schema)}

  ## General Parameters
  #{NimbleOptions.docs(@general_schema)}

  ## Tree Booster Parameters
  #{NimbleOptions.docs(@tree_booster_schema)}

  ## Linear Booster Parameters
  #{NimbleOptions.docs(@linear_booster_schema)}

  ## Dart Booster Parameters
  #{NimbleOptions.docs(@dart_booster_schema)}

  ## Learning Task Parameters
  #{NimbleOptions.docs(@learning_task_schema)}

  ## Objective-Specific Parameters

  ### Tweedie Regression Parameters
  #{NimbleOptions.docs(@tweedie_schema)}

  ### Pseudo-Huber Error Parameters
  #{NimbleOptions.docs(@pseudohubererror_schema)}

  ### Quantile Error Parameters
  #{NimbleOptions.docs(@quantileerror_schema)}

  ### Survival Analysis Parameters
  #{NimbleOptions.docs(@survival_schema)}

  ### Ranking Parameters
  #{NimbleOptions.docs(@ranking_schema)}

  ### Multi-Class Classification Parameters
  #{NimbleOptions.docs(@multi_soft_schema)}
  """

  @doc false
  def validate_global!(params) when is_map(params) do
    Keyword.new(params)
    |> Keyword.take(Keyword.keys(@global_params))
    |> NimbleOptions.validate!(@global_schema)
    |> Map.new()
  end

  @doc """
  Validates the EXGBoost parameters and returns a keyword list of the validated parameters.
  """
  @spec validate!(keyword()) :: keyword()
  def validate!(params) when is_list(params) do
    # Get some of the params that other params depend on
    general_params =
      Keyword.take(params, Keyword.keys(@general_params))
      |> NimbleOptions.validate!(@general_schema)

    params =
      if general_params[:validate_parameters] do
        booster_params =
          case general_params[:booster] do
            :gbtree ->
              Keyword.take(params, Keyword.keys(@tree_booster_params))
              |> NimbleOptions.validate!(@tree_booster_schema)

            :gblinear ->
              Keyword.take(params, Keyword.keys(@linear_booster_params))
              |> NimbleOptions.validate!(@linear_booster_schema)

            :dart ->
              Keyword.take(params, Keyword.keys(@dart_booster_params))
              |> NimbleOptions.validate!(@dart_booster_schema)
          end

        learning_task_params =
          Keyword.take(params, Keyword.keys(@learning_task_params))
          |> NimbleOptions.validate!(@learning_task_schema)

        extra_params =
          case learning_task_params[:objective] do
            "reg:tweedie" ->
              Keyword.take(params, Keyword.keys(@tweedie_params))
              |> NimbleOptions.validate!(@tweedie_schema)

            "reg:pseudohubererror" ->
              Keyword.take(params, Keyword.keys(@pseudohubererror_params))
              |> NimbleOptions.validate!(@pseudohubererror_schema)

            "reg:quantileerror" ->
              Keyword.take(params, Keyword.keys(@quantileerror_params))
              |> NimbleOptions.validate!(@quantileerror_schema)

            "survival:aft" ->
              Keyword.take(params, Keyword.keys(@survival_params))
              |> NimbleOptions.validate!(@survival_schema)

            "rank:ndcg" ->
              Keyword.take(params, Keyword.keys(@ranking_params))
              |> NimbleOptions.validate!(@ranking_schema)

            "rank:map" ->
              Keyword.take(params, Keyword.keys(@ranking_params))
              |> NimbleOptions.validate!(@ranking_schema)

            "rank:pairwise" ->
              Keyword.take(params, Keyword.keys(@ranking_params))
              |> NimbleOptions.validate!(@ranking_schema)

            "multi:softmax" ->
              Keyword.take(params, Keyword.keys(@multi_soft_params))
              |> NimbleOptions.validate!(@multi_soft_schema)

            "multi:softprob" ->
              Keyword.take(params, Keyword.keys(@multi_soft_params))
              |> NimbleOptions.validate!(@multi_soft_schema)

            _ ->
              []
          end

        general_params ++ booster_params ++ learning_task_params ++ extra_params
      else
        params
      end

    params
  end
end
