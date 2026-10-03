{3, 4, 2} = EXGBoost.xgboost_version()
x = Nx.tensor([[0.0, 1.0], [1.0, 0.0], [2.0, 1.0], [3.0, 0.0]])
y = Nx.tensor([0.0, 1.0, 2.0, 3.0])
booster = EXGBoost.train(x, y, num_boost_rounds: 3, nthread: 1, verbose_eval: false)
predictions = EXGBoost.predict(booster, x)
true = Nx.all_close(predictions, EXGBoost.inplace_predict(booster, x)) |> Nx.to_number() |> Kernel.==(1)
for format <- [:json, :ubj] do
  weights = EXGBoost.dump_weights(booster, format: format)
  restored = EXGBoost.load_weights(weights)
  true = Nx.all_close(predictions, EXGBoost.predict(restored, x)) |> Nx.to_number() |> Kernel.==(1)
end
IO.puts("Packaged XGBoost 3.4.2: training, dense/in-place prediction and JSON/UBJ round-trips passed")
