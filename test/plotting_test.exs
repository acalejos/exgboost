defmodule EXGBoost.PlottingTest do
  use ExUnit.Case, async: true

  setup_all do
    x = Nx.tensor([[0.0], [1.0], [2.0], [3.0]])
    y = Nx.tensor([0.0, 0.0, 2.0, 2.0])

    booster =
      EXGBoost.train(x, y,
        num_boost_rounds: 2,
        min_child_weight: 0,
        max_depth: 2,
        nthread: 1,
        verbose_eval: false
      )

    %{booster: booster}
  end

  test "the default plot validates against the bundled schema", %{booster: booster} do
    plot = EXGBoost.plot_tree(booster)
    spec = VegaLite.to_spec(plot)
    assert spec["$schema"] == "https://vega.github.io/schema/vega/v5.json"
    assert is_list(spec["marks"])
    assert is_list(spec["data"])
    assert Jason.encode!(spec)
  end

  test "styles and layout directions produce valid Vega specs", %{booster: booster} do
    for rankdir <- [:tb, :bt, :lr, :rl] do
      plot = EXGBoost.plot_tree(booster, rankdir: rankdir, style: :horizon_light, index: nil)
      assert %{"marks" => marks} = VegaLite.to_spec(plot)
      assert is_list(marks)
    end
  end

  test "tabular trees retain parent links and distinct tree identifiers", %{booster: booster} do
    nodes = EXGBoost.Plotting.to_tabular(booster)
    assert MapSet.new(Enum.map(nodes, & &1["tree_id"])) == MapSet.new([0, 1])

    for tree <- Enum.group_by(nodes, & &1["tree_id"]) |> Map.values() do
      ids = MapSet.new(Enum.map(tree, & &1["nodeid"]))
      assert Enum.any?(tree, &is_nil(&1["parentid"]))
      assert Enum.all?(tree, &(is_nil(&1["parentid"]) or &1["parentid"] in ids))
    end
  end
end
