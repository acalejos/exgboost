defmodule EXGBoost.MaintenanceTest do
  use ExUnit.Case, async: true
  alias EXGBoost.{Booster, DMatrix}

  setup do
    x = Nx.tensor([[0.0, 1.0], [1.0, 0.0], [2.0, 1.0], [3.0, 0.0]])
    %{x: x, y: Nx.tensor([0.0, 1.0, 2.0, 3.0])}
  end

  test "unpatched upstream selects the regression default metric for early stopping", %{
    x: x,
    y: y
  } do
    booster =
      EXGBoost.train(x, y,
        early_stopping_rounds: 1,
        evals: [{x, y, "validation-set"}],
        verbose_eval: false,
        nthread: 1
      )

    assert is_number(booster.best_score)
    config = EXGBoost.dump_config(booster) |> Jason.decode!()
    refute Map.has_key?(config["learner"], "default_metric")
    assert [%{"name" => "rmse"}] = config["learner"]["metrics"]
  end

  test "unpatched upstream selects a classification default metric", %{x: x} do
    y = Nx.tensor([0.0, 0.0, 1.0, 1.0])

    booster =
      EXGBoost.train(x, y,
        objective: :binary_logistic,
        early_stopping_rounds: 1,
        evals: [{x, y, "validation"}],
        verbose_eval: false,
        nthread: 1
      )

    assert is_number(booster.best_score)
    config = EXGBoost.dump_config(booster) |> Jason.decode!()
    assert [%{"name" => "logloss"}] = config["learner"]["metrics"]
  end

  test "disabling the default metric reaches upstream and requires an explicit metric", %{
    x: x,
    y: y
  } do
    assert_raise ArgumentError, ~r/requires an evaluation metric/, fn ->
      EXGBoost.train(x, y,
        early_stopping_rounds: 1,
        evals: [{x, y, "validation"}],
        disable_default_eval_metric: true,
        verbose_eval: false
      )
    end

    booster =
      EXGBoost.train(x, y,
        early_stopping_rounds: 1,
        evals: [{x, y, "validation"}],
        disable_default_eval_metric: true,
        eval_metric: :mae,
        verbose_eval: false,
        nthread: 1
      )

    assert is_number(booster.best_score)
  end

  test "custom metrics return values and drive early stopping without a built-in metric", %{
    x: x,
    y: y
  } do
    feval = fn _predictions, _dmat -> [{"constant-metric", 2.5}, {"last.metric", 7.0}] end

    booster =
      EXGBoost.train(x, y,
        feval: feval,
        disable_default_eval_metric: true,
        early_stopping_rounds: 1,
        num_boost_rounds: 10,
        evals: [{x, y, "validation-set"}],
        verbose_eval: false,
        nthread: 1
      )

    assert Booster.get_boosted_rounds(booster) == 2
    assert booster.best_iteration == 1
    assert booster.best_score == 7.0
    dmat = DMatrix.from_tensor(x, y, format: :dense)

    assert [{"eval", "constant-metric", 2.5}, {"eval", "last.metric", 7.0}] =
             Booster.eval(booster, dmat, feval: feval)
  end

  test "maximize preserves the best round when a custom metric deteriorates", %{x: x, y: y} do
    feval = fn _predictions, _dmat -> {"score", Process.get(:metric_score, 3.0)} end

    callback =
      EXGBoost.Training.Callback.new(
        :before_iteration,
        fn state ->
          Process.put(:metric_score, 3.0 - state.iteration)
          state
        end,
        :decreasing_metric
      )

    booster =
      EXGBoost.train(x, y,
        callbacks: [callback],
        feval: feval,
        maximize: true,
        disable_default_eval_metric: true,
        early_stopping_rounds: 1,
        evals: [{x, y, "validation"}],
        verbose_eval: false,
        nthread: 1
      )

    assert booster.best_iteration == 1
    assert booster.best_score == 3.0
    assert Booster.get_boosted_rounds(booster) == 2
  end

  test "labels with a mismatched row count produce a useful error", %{x: x} do
    assert_raise ArgumentError, ~r/same number of rows/, fn ->
      DMatrix.from_tensor(x, Nx.tensor([1.0]), format: :dense)
    end
  end

  test "deprecated file wrapper uses the supported upstream URI API" do
    assert {:ok, ref} =
             apply(EXGBoost.NIF, :dmatrix_create_from_file, [
               "test/data/train.txt?format=libsvm",
               1
             ])

    assert {:ok, rows} = EXGBoost.NIF.dmatrix_num_row(ref)
    assert rows > 0
  end

  test "precompiler rejects a target different from this host" do
    {:ok, current} = EXGBoost.Precompiler.current_target()
    other = EXGBoost.Precompiler.all_supported_targets(:fetch) |> Enum.find(&(&1 != current))
    assert {:error, _} = EXGBoost.Precompiler.precompile([], other)
    assert EXGBoost.Precompiler.all_supported_targets(:compile) == [current]
  end
end
