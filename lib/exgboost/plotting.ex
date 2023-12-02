defmodule EXGBoost.Plotting.Schema do
  defmacro __before_compile__(_env) do
    HTTPoison.start()

    schema = HTTPoison.get!("https://vega.github.io/schema/vega/v5.json").body

    quote do
      require Exonerate
      Exonerate.function_from_string(:def, :validate, unquote(schema), dump: true, metadata: true)
    end
    |> Code.compile_quoted()
  end
end

defmodule EXGBoost.Plotting do
  @before_compile EXGBoost.Plotting.Schema

  @plotting_params [
    height: [
      description: "Height of the plot in pixels",
      type: :pos_integer,
      default: 400
    ],
    width: [
      description: "Width of the plot in pixels",
      type: :pos_integer,
      default: 600
    ],
    padding: [
      description:
        "The padding in pixels to add around the visualization. If a number, specifies padding for all sides. If an object, the value should have the format `[left: value, right: value, top: value, bottom: value]`",
      type:
        {:or,
         [
           :pos_integer,
           keyword_list: [
             left: [type: :pos_integer],
             right: [type: :pos_integer],
             top: [type: :pos_integer],
             bottom: [type: :pos_integer]
           ]
         ]},
      default: 5
    ]
  ]

  defp _to_tabular(idx, node, parent) do
    node = Map.put(node, "tree_id", idx)
    node = if parent, do: Map.put(node, "parentid", parent), else: node
    node = new_node(node)

    if Map.has_key?(node, "children") do
      [
        Map.delete(node, "children")
        | Enum.flat_map(Map.get(node, "children"), fn child ->
            to_tabular(idx, child, Map.get(node, "nodeid"))
          end)
      ]
    else
      [node]
    end
  end

  defp new_node(params = %{}) do
    Map.merge(
      %{
        "nodeid" => nil,
        "depth" => nil,
        "missing" => nil,
        "no" => nil,
        "leaf" => nil,
        "split" => nil,
        "split_condition" => nil,
        "yes" => nil,
        "tree_id" => nil,
        "parentid" => nil
      },
      params
    )
  end

  @doc """
  Outputs details of the tree in a tabular format which can be consumed
  by plotting libraries such as Vega. Outputs as a list of maps, where
  each map represents a node in the tree.

  Table columns:
  - tree_id: The tree id
  - nodeid: The node id
  - parentid: The parent node id
  - split: The split feature
  - split_condition: The split condition
  - yes: The node id of the left child
  - no: The node id of the right child
  - missing: The node id of the missing child
  - depth: The depth of the node
  - leaf: The leaf value if it is a leaf node
  """
  def to_tabular(booster) do
    booster
    |> EXGBoost.Booster.get_dump(format: :json)
    |> Enum.map(&Jason.decode!(&1))
    |> Enum.with_index()
    |> Enum.reduce(
      [],
      fn {tree, index}, acc ->
        acc ++ _to_tabular(index, tree, nil)
      end
    )
  end

  defp to_vega(booster) do
    tabular =
      booster
      |> EXGBoost.Booster.get_dump(format: :json)
      |> Enum.map(&Jason.decode!(&1))
      |> Enum.with_index()
      |> Enum.reduce(
        [],
        fn {tree, index}, acc ->
          acc ++ to_tabular(index, tree, nil)
        end
      )

    spec = %{
      "$schema" => "https://vega.github.io/schema/vega/v5.json",
      "description" => "A basic decision tree layout of nodes",
      "width" => 800,
      "height" => 600,
      "padding" => 5,
      "signals" => [
        %{
          "name" => "treeSelector",
          "value" => 0,
          "bind" => %{
            "input" => "select",
            "options" =>
              tabular
              |> Enum.reduce([], fn node, acc ->
                id = Map.get(node, "tree_id")
                if id in acc, do: acc, else: [id | acc]
              end)
              |> Enum.sort()
          }
        }
      ],
      "data" => [
        %{
          "name" => "tree",
          "values" => tabular,
          "transform" => [
            %{
              "type" => "filter",
              "expr" => "datum.tree_id === treeSelector"
            },
            %{
              "type" => "stratify",
              "key" => "nodeid",
              "parentKey" => "parentid"
            },
            %{
              "type" => "tree",
              "size" => [%{"signal" => "width"}, %{"signal" => "height"}],
              "as" => ["x", "y", "depth", "children"]
            }
          ]
        },
        %{
          "name" => "links",
          "source" => "tree",
          "transform" => [
            %{"type" => "treelinks"},
            %{
              "type" => "linkpath",
              "shape" => "line"
            }
          ]
        },
        %{
          "name" => "innerNodes",
          "source" => "tree",
          "transform" => [
            %{"type" => "filter", "expr" => "datum.leaf == null"}
          ]
        },
        %{
          "name" => "leafNodes",
          "source" => "tree",
          "transform" => [
            %{"type" => "filter", "expr" => "datum.leaf != null"}
          ]
        }
      ],
      "scales" => [
        %{
          "name" => "color",
          "type" => "ordinal",
          "domain" => %{"data" => "tree", "field" => "depth"},
          "range" => %{"scheme" => "category10"}
        }
      ],
      "marks" => [
        %{
          "type" => "path",
          "from" => %{"data" => "links"},
          "encode" => %{
            "update" => %{
              "path" => %{"field" => "path"},
              "stroke" => %{"value" => "#ccc"}
            }
          }
        },
        %{
          "type" => "text",
          "from" => %{"data" => "tree"},
          "encode" => %{
            "enter" => %{
              "text" => %{
                "signal" =>
                  "datum.split ? datum.split + ' <= ' + format(datum.split_condition, '.2f') : ''"
              },
              "fontSize" => %{"value" => 10},
              "baseline" => %{"value" => "middle"},
              "align" => %{"value" => "center"},
              "dx" => %{"value" => 0},
              "dy" => %{"value" => 0}
            },
            "update" => %{
              "x" => %{"field" => "x"},
              "y" => %{"field" => "y"},
              "fill" => %{"value" => "black"}
            }
          }
        },
        %{
          "type" => "symbol",
          "from" => %{"data" => "innerNodes"},
          "encode" => %{
            "enter" => %{
              "fill" => %{"value" => "none"},
              "shape" => %{"value" => "circle"},
              "x" => %{"field" => "x"},
              "y" => %{"field" => "y"},
              "size" => %{"value" => 800}
            },
            "update" => %{
              "fill" => %{"scale" => "color", "field" => "depth"},
              "opacity" => %{"value" => 1},
              "stroke" => %{"value" => "black"},
              "strokeWidth" => %{"value" => 1},
              "fillOpacity" => %{"value" => 0},
              "strokeOpacity" => %{"value" => 1}
            }
          }
        },
        %{
          "type" => "rect",
          "from" => %{"data" => "leafNodes"},
          "encode" => %{
            "enter" => %{
              "x" => %{"signal" => "datum.x - 20"},
              "y" => %{"signal" => "datum.y - 10"},
              "width" => %{"value" => 40},
              "height" => %{"value" => 20},
              "stroke" => %{"value" => "black"},
              "fill" => %{"value" => "transparent"}
            }
          }
        },
        %{
          "type" => "text",
          "from" => %{"data" => "tree"},
          "encode" => %{
            "enter" => %{
              "text" => %{
                "signal" => "format(datum.leaf, '.2f')"
              },
              "fontSize" => %{"value" => 10},
              "baseline" => %{"value" => "middle"},
              "align" => %{"value" => "center"},
              "dx" => %{"value" => 0},
              "dy" => %{"value" => 0}
            },
            "update" => %{
              "x" => %{"field" => "x"},
              "y" => %{"field" => "y"},
              "fill" => %{"value" => "black"},
              "opacity" => %{"signal" => "datum.leaf != null ? 1 : 0"}
            }
          }
        },
        %{
          "type" => "text",
          "from" => %{"data" => "links"},
          "encode" => %{
            "enter" => %{
              "x" => %{"signal" => "(datum.source.x + datum.target.x) / 2"},
              "y" => %{"signal" => "(datum.source.y + datum.target.y) / 2"},
              "text" => %{
                "signal" => "datum.source.yes === datum.target.nodeid ? 'yes' : 'no'"
              },
              "align" => %{"value" => "center"},
              "baseline" => %{"value" => "middle"}
            }
          }
        }
      ]
    }

    Jason.encode!(spec) |> VegaLite.from_json()
  end
end

defimpl Kino.Render, for: EXGBoost.Booster do
  def to_livebook(booster) do
    Kino.Render.to_livebook(EXGBoost.Plotting.to_vega(booster))
  end
end
