# defmodule EXGBoost.Plotting.Schema do
#   @moduledoc false
#   Code.ensure_compiled!(ExJsonSchema)

#   defmacro __before_compile__(_env) do
#     HTTPoison.start()

#     schema =
#       HTTPoison.get!("https://vega.github.io/schema/vega/v5.json").body
#       |> Jason.decode!()
#       |> ExJsonSchema.Schema.resolve()
#       |> Macro.escape()

#     quote do
#       def get_schema(), do: unquote(schema)
#     end
#   end
# end

defmodule EXGBoost.Plotting do
  @moduledoc """
  Functions for plotting EXGBoost `Booster` models using [Vega](https://vega.github.io/vega/)

  Fundamentally, all this module does is convert a `Booster` into a format that can be
  ingested by Vega, and apply some default configuations that only account for a subset of the configurations
  that can be set by a Vega spec directly. The functions provided in this module are designed to have opinionated
  defaults that can be used to quickly visualize a model, but the full power of Vega is available by using the
  `to_tabular/1` function to convert the model into a tabular format, and then using the `to_vega/2` function
  to convert the tabular format into a Vega specification.

  ## Default Vega Specification

  The default Vega specification is designed to be a good starting point for visualizing a model, but it is
  possible to customize the specification by passing in a map of Vega properties to the `to_vega/2` function.
  Refer to `Custom Vega Specifications` for more details on how to do this.

  By default, the Vega specification includes the following entities to use for rendering the model:
  * `:width` - The width of the plot in pixels
  * `:height` - The height of the plot in pixels
  * `:padding` - The padding in pixels to add around the visualization. If a number, specifies padding for all sides. If an object, the value should have the format `[left: value, right: value, top: value, bottom: value]`
  * `:leafs` - Specifies characteristics of leaf nodes
  * `:inner_nodes` - Specifies characteristics of inner nodes
  * `:links` - Specifies characteristics of links between nodes

  ## Custom Vega Specifications

  The default Vega specification is designed to be a good starting point for visualizing a model, but it is
  possible to customize the specification by passing in a map of Vega properties to the `to_vega/2` function.
  You can find the full list of Vega properties [here](https://vega.github.io/vega/docs/specification/).

  It is suggested that you use the data attributes provided by the default specification as a starting point, since they
  provide the necessary data transformation to convert the model into a tree structure that can be visualized by Vega.
  If you would like to customize the default specification, you can use `EXGBoost.Plotting.to_vega/1` to get the default
  specification, and then modify it as needed.

  Once you have a custom specification, you can pass it to `VegaLite.from_json/1` to create a new `VegaLite` struct, after which
  you can use the functions provided by the `VegaLite` module to render the model.

  ## Specification Validation
  You can optionally validate your specification against the Vega schema by passing the `validate: true` option to `to_vega/2`.
  This will raise an error if the specification is invalid. This is useful if you are creating a custom specification and want
  to ensure that it is valid. Note that this will only validate the specification against the Vega schema, and not against the
  VegaLite schema. This requires the [`ex_json_schema`] package to be installed.

  ## Livebook Integration

  This module also provides a `Kino.Render` implementation for `EXGBoost.Booster` which allows
  models to be rendered directly in Livebook. This is done by converting the model into a Vega specification
  and then using the `Kino.Render` implementation for Elixir's [`VegaLite`](https://hexdocs.pm/vega_lite/VegaLite.html) API
  to render the model.


  . The Vega specification is then passed to [VegaLite](https://hexdocs.pm/vega_lite/readme.html)


  """

  HTTPoison.start()

  @schema HTTPoison.get!("https://vega.github.io/schema/vega/v5.json").body
          |> Jason.decode!()
          |> ExJsonSchema.Schema.resolve()

  @plotting_params [
    autosize: [
      doc:
        "Determines if the visualization should automatically resize when the window size changes",
      type: {:in, ["fit", "pad", "fit-x", "fit-y", "none"]},
      default: "fit"
    ],
    background: [
      doc:
        "The background color of the visualization. Accepts a valid CSS color string. For example: `#f304d3`, `#ccc`, `rgb(253, 12, 134)`, `steelblue.`",
      type: :string,
      default: "#f5f5f5"
    ],
    height: [
      doc: "Height of the plot in pixels",
      type: :pos_integer,
      default: 400
    ],
    width: [
      doc: "Width of the plot in pixels",
      type: :pos_integer,
      default: 600
    ],
    padding: [
      doc:
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
    ],
    leaves: [
      doc: "Specifies characteristics of leaf nodes",
      type: :keyword_list,
      keys: [
        fill: [type: :string, default: "#ccc"],
        stroke: [type: :string, default: "black"],
        stroke_width: [type: :pos_integer, default: 1],
        font_size: [type: :pos_integer, default: 13]
      ],
      default: [
        fill: "#ccc",
        stroke: "black",
        stroke_width: 1,
        font_size: 13
      ]
    ],
    node_width: [
      doc: "The width of each node in pixels",
      type: :pos_integer,
      default: 100
    ],
    node_height: [
      doc: "The height of each node in pixels",
      type: :pos_integer,
      default: 45
    ],
    space_between: [
      type: :keyword_list,
      keys: [
        nodes: [type: :pos_integer, default: 10],
        levels: [type: :pos_integer, default: 100]
      ],
      default: [nodes: 10, levels: 100]
    ],
    splits: [
      doc: "Specifies characteristics of inner nodes",
      type: :keyword_list,
      keys: [
        fill: [type: :string, default: "#ccc"],
        stroke: [type: :string, default: "black"],
        stroke_width: [type: :pos_integer, default: 1],
        font_size: [type: :pos_integer, default: 13]
      ],
      default: [
        fill: "#ccc",
        stroke: "black",
        stroke_width: 1,
        font_size: 13
      ]
    ],
    links: [
      doc: "Specifies characteristics of links between nodes",
      type: :keyword_list,
      keys: [
        fill: [type: :string, default: "#ccc"],
        stroke: [type: :string, default: "black"],
        stroke_width: [type: :pos_integer, default: 1],
        font_size: [type: :pos_integer, default: 13]
      ],
      default: [
        fill: "#ccc",
        stroke: "black",
        stroke_width: 1,
        font_size: 13
      ]
    ],
    validate: [
      doc: "Whether to validate the Vega specification against the Vega schema",
      type: :boolean,
      default: true
    ],
    index: [
      doc:
        "The zero-indexed index of the tree to plot. If `nil`, plots all trees using a dropdown selector to switch between trees",
      type: {:or, [nil, :non_neg_integer]},
      default: 0
    ],
    depth: [
      doc:
        "The depth of the tree to plot. If `nil`, plots all levels (cick on a node to expand/collapse)",
      type: {:or, [nil, :non_neg_integer]},
      default: nil
    ]
  ]

  @plotting_schema NimbleOptions.new!(@plotting_params)

  def get_schema(), do: @schema

  defp validate_spec(spec) do
    case ExJsonSchema.Validator.validate(get_schema(), spec) do
      :ok ->
        spec

      {:error, errors} ->
        raise(
          ArgumentError,
          "Invalid Vega specification: #{inspect(errors)}"
        )
    end
  end

  defp _to_tabular(idx, node, parent) do
    node = Map.put(node, "tree_id", idx)
    node = if parent, do: Map.put(node, "parentid", parent), else: node

    node =
      new_node(node)
      |> Map.update("nodeid", nil, &(&1 + 1))
      |> Map.update("yes", nil, &if(&1, do: &1 + 1))
      |> Map.update("no", nil, &if(&1, do: &1 + 1))

    if Map.has_key?(node, "children") do
      [
        Map.delete(node, "children")
        | Enum.flat_map(Map.get(node, "children"), fn child ->
            _to_tabular(idx, child, Map.get(node, "nodeid"))
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

  @doc """
  Generates the necessary data transformation to convert the model into a tree structure that can be visualized by Vega.

  This function is useful if you want to create a custom Vega specification, but still want to use the data transformation
  provided by the default specification.
  """
  def get_data_spec(booster) do
    %{
      "$schema" => "https://vega.github.io/schema/vega/v5.json",
      "data" => [
        %{"name" => "tree", "values" => to_tabular(booster)},
        %{
          "name" => "treeCalcs",
          "source" => "tree",
          "transform" => [
            %{"expr" => "datum.tree_id === selectedTree", "type" => "filter"},
            %{"key" => "nodeid", "parentKey" => "parentid", "type" => "stratify"},
            %{
              "as" => ["y", "x", "depth", "children"],
              "method" => "tidy",
              "separation" => %{"signal" => "false"},
              "type" => "tree"
            }
          ]
        },
        %{
          "name" => "treeChildren",
          "source" => "treeCalcs",
          "transform" => [
            %{
              "as" => ["childrenObjects"],
              "fields" => ["parentid"],
              "groupby" => ["parentid"],
              "ops" => ["values"],
              "type" => "aggregate"
            },
            %{
              "as" => "childrenIds",
              "expr" => "pluck(datum.childrenObjects,'nodeid')",
              "type" => "formula"
            }
          ]
        },
        %{
          "name" => "treeAncestors",
          "source" => "treeCalcs",
          "transform" => [
            %{
              "as" => "treeAncestors",
              "expr" => "treeAncestors('treeCalcs', datum.nodeid, 'root')",
              "type" => "formula"
            },
            %{"fields" => ["treeAncestors"], "type" => "flatten"},
            %{
              "as" => "allParents",
              "expr" => "datum.treeAncestors.parentid",
              "type" => "formula"
            }
          ]
        },
        %{
          "name" => "treeChildrenAll",
          "source" => "treeAncestors",
          "transform" => [
            %{
              "fields" => [
                "allParents",
                "nodeid",
                "name",
                "parentid",
                "x",
                "y",
                "depth",
                "children"
              ],
              "type" => "project"
            },
            %{
              "as" => ["allChildrenObjects", "allChildrenCount", "id"],
              "fields" => ["parentid", "parentid", "nodeid"],
              "groupby" => ["allParents"],
              "ops" => ["values", "count", "min"],
              "type" => "aggregate"
            },
            %{
              "as" => "allChildrenIds",
              "expr" => "pluck(datum.allChildrenObjects,'nodeid')",
              "type" => "formula"
            }
          ]
        },
        %{
          "name" => "treeClickStoreTemp",
          "source" => "treeAncestors",
          "transform" => [
            %{
              "expr" =>
                "startingDepth != -1 ? datum.depth <= startingDepth : node != 0 && !isExpanded ? datum.parentid == node: node != 0 && isExpanded ? datum.allParents == node : false",
              "type" => "filter"
            },
            %{
              "fields" => ["nodeid", "parentid", "x", "y", "depth", "children"],
              "type" => "project"
            },
            %{
              "fields" => ["nodeid"],
              "groupby" => ["nodeid", "parentid", "x", "y", "depth", "children"],
              "ops" => ["min"],
              "type" => "aggregate"
            }
          ]
        },
        %{
          "name" => "treeClickStorePerm",
          "on" => [
            %{"insert" => "data('treeClickStoreTemp')", "trigger" => "startingDepth >= 0"},
            %{
              "insert" => "!isExpanded ? data('treeClickStoreTemp'): false",
              "trigger" => "node"
            },
            %{"remove" => "isExpanded ? data('treeClickStoreTemp'): false", "trigger" => "node"}
          ],
          "values" => []
        },
        %{
          "name" => "treeLayout",
          "source" => "tree",
          "transform" => [
            %{"expr" => "datum.tree_id === selectedTree", "type" => "filter"},
            %{
              "expr" => "indata('treeClickStorePerm', 'nodeid', datum.nodeid)",
              "type" => "filter"
            },
            %{"key" => "nodeid", "parentKey" => "parentid", "type" => "stratify"},
            %{
              "as" => ["x", "y", "depth", "children"],
              "method" => "tidy",
              "nodeSize" => [
                %{"signal" => "nodeWidth + spaceBetweenNodes"},
                %{"signal" => "nodeHeight+ spaceBetweenLevels"}
              ],
              "separation" => %{"signal" => "false"},
              "type" => "tree"
            },
            %{"as" => "y", "expr" => "datum.y+(height/10)", "type" => "formula"},
            %{"as" => "x", "expr" => "datum.x+(width/2)", "type" => "formula"},
            %{"as" => "xscaled", "expr" => "scale('xscale',datum.x)", "type" => "formula"},
            %{"as" => "parent", "expr" => "datum.parentid", "type" => "formula"}
          ]
        },
        %{
          "name" => "fullTreeLayout",
          "source" => "treeLayout",
          "transform" => [
            %{
              "fields" => ["nodeid"],
              "from" => "treeChildren",
              "key" => "parentid",
              "type" => "lookup",
              "values" => ["childrenObjects", "childrenIds"]
            },
            %{
              "fields" => ["nodeid"],
              "from" => "treeChildrenAll",
              "key" => "allParents",
              "type" => "lookup",
              "values" => ["allChildrenIds", "allChildrenObjects"]
            },
            %{
              "fields" => ["nodeid"],
              "from" => "treeCalcs",
              "key" => "nodeid",
              "type" => "lookup",
              "values" => ["children"]
            },
            %{
              "as" => "treeParent",
              "expr" => "reverse(pluck(treeAncestors('treeCalcs', datum.nodeid), 'nodeid'))[1]",
              "type" => "formula"
            },
            %{"as" => "isLeaf", "expr" => "datum.leaf == null", "type" => "formula"}
          ]
        },
        %{
          "name" => "visibleNodes",
          "source" => "fullTreeLayout",
          "transform" => [
            %{
              "expr" => "indata('treeClickStorePerm', 'nodeid', datum.nodeid)",
              "type" => "filter"
            }
          ]
        },
        %{
          "name" => "links",
          "source" => "treeLayout",
          "transform" => [
            %{"type" => "treelinks"},
            %{
              "orient" => "vertical",
              "shape" => "line",
              "sourceX" => %{"expr" => "scale('xscale', datum.source.x)"},
              "sourceY" => %{"expr" => "scale('yscale', datum.source.y)"},
              "targetX" => %{"expr" => "scale('xscale', datum.target.x)"},
              "targetY" => %{"expr" => "scale('yscale', datum.target.y) - scaledNodeHeight"},
              "type" => "linkpath"
            },
            %{
              "expr" => " indata('treeClickStorePerm', 'nodeid', datum.target.nodeid)",
              "type" => "filter"
            }
          ]
        }
      ]
    }
  end

  def to_vega(booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @plotting_schema)
    spec = get_data_spec(booster)

    [%{"$ref" => root} | [%{"properties" => properties}]] =
      EXGBoost.Plotting.get_schema().schema |> Map.get("allOf")

    top_level_keys =
      (ExJsonSchema.Schema.get_fragment!(EXGBoost.Plotting.get_schema(), root)
       |> Map.get("properties")
       |> Map.keys()) ++ Map.keys(properties)

    tlk = opts |> opts_to_vl_props() |> Map.take(top_level_keys)

    spec =
      Map.merge(spec, %{
        "$schema" => "https://vega.github.io/schema/vega/v5.json",
        "marks" => [
          %{
            "encode" => %{
              "update" => %{
                "path" => %{"field" => "path"},
                "stroke" => %{
                  "signal" => "datum.source.yes === datum.target.nodeid ? 'red' : 'black'"
                },
                "strokeWidth" => %{
                  "signal" => "indexof(nodeHighlight, datum.target.nodeid)> -1? 2:1"
                }
              }
            },
            "from" => %{"data" => "links"},
            "interactive" => false,
            "type" => "path"
          },
          %{
            "encode" => %{
              "update" => %{
                "align" => %{"value" => "center"},
                "baseline" => %{"value" => "middle"},
                "fontSize" => %{"signal" => "linksFontSize"},
                "text" => %{"signal" => "datum.source.yes === datum.target.nodeid ? 'yes' : 'no'"},
                "x" => %{
                  "signal" =>
                    "(scale('xscale', datum.source.x+(nodeWidth/3)) + scale('xscale', datum.target.x)) / 2"
                },
                "y" => %{
                  "signal" =>
                    "(scale('yscale', datum.source.y) + scale('yscale', datum.target.y)) / 2 - (scaledNodeHeight/2)"
                }
              }
            },
            "from" => %{"data" => "links"},
            "type" => "text"
          },
          %{
            "clip" => false,
            "description" => "The parent node",
            "encode" => %{
              "update" => %{
                "cornerRadius" => %{"value" => 2},
                "cursor" => %{"signal" => "datum.children > 0 ? 'pointer' : '' "},
                "fill" => %{"signal" => "datum.isLeaf ? leafColor : splitColor"},
                "height" => %{"signal" => "scaledNodeHeight"},
                "opacity" => %{"value" => 0},
                "tooltip" => %{"signal" => ""},
                "width" => %{"signal" => "scaledNodeWidth"},
                "x" => %{"signal" => "datum.xscaled - (scaledNodeWidth / 2)"},
                "yc" => %{"signal" => "scale('yscale',datum.y) - (scaledNodeHeight/2)"}
              }
            },
            "from" => %{"data" => "visibleNodes"},
            "marks" => [
              %{
                "description" =>
                  "highlight (seems like a Vega bug as this doens't work on the group element)",
                "encode" => %{
                  "update" => %{
                    "fill" => %{"signal" => "parent.isLeaf ? leafColor : splitColor"},
                    "height" => %{"signal" => "item.mark.group.height"},
                    "width" => %{"signal" => "item.mark.group.width"},
                    "x" => %{"signal" => "item.mark.group.x1"},
                    "y" => %{"signal" => "0"}
                  }
                },
                "interactive" => false,
                "name" => "highlight",
                "type" => "rect"
              },
              %{
                "encode" => %{
                  "update" => %{
                    "align" => %{"value" => "center"},
                    "baseline" => %{"value" => "middle"},
                    "fill" => %{"signal" => "'black'"},
                    "font" => %{"value" => "Calibri"},
                    "fontSize" => %{"signal" => "parent.split ? splitsFontSize : leavesFontSize"},
                    "limit" => %{"signal" => "scaledNodeWidth-scaledLimit"},
                    "text" => %{
                      "signal" =>
                        "parent.split ? parent.split + ' <= ' + format(parent.split_condition, '.2f') : 'leaf = ' + format(parent.leaf, '.2f')"
                    },
                    "x" => %{"signal" => "(scaledNodeWidth / 2)"},
                    "y" => %{"signal" => "scaledNodeHeight / 2"}
                  }
                },
                "interactive" => false,
                "name" => "title",
                "type" => "text"
              },
              %{
                "encode" => %{
                  "update" => %{
                    "align" => %{"value" => "right"},
                    "baseline" => %{"value" => "middle"},
                    "fill" => %{"signal" => "childrenColor"},
                    "font" => %{"value" => "Calibri"},
                    "fontSize" => %{"signal" => "splitsFontSize"},
                    "text" => %{"signal" => "parent.children > 0 ? parent.children :''"},
                    "x" => %{"signal" => "item.mark.group.width - (9/ span(xdom))*width"},
                    "y" => %{"signal" => "item.mark.group.height/2"}
                  }
                },
                "interactive" => false,
                "name" => "node children",
                "type" => "text"
              }
            ],
            "name" => "node",
            "type" => "group"
          }
        ],
        "scales" => [
          %{
            "domain" => %{"signal" => "xdom"},
            "name" => "xscale",
            "range" => %{"signal" => "xrange"},
            "zero" => false
          },
          %{
            "domain" => %{"signal" => "ydom"},
            "name" => "yscale",
            "range" => %{"signal" => "yrange"},
            "zero" => false
          }
        ],
        "signals" => [
          Map.merge(
            %{
              "name" => "selectedTree",
              "value" => opts[:index] || 0
            },
            if(opts[:index],
              do: %{},
              else: %{
                "bind" => %{
                  "input" => "select",
                  "options" =>
                    to_tabular(booster)
                    |> Enum.reduce([], fn node, acc ->
                      id = Map.get(node, "tree_id")
                      if id in acc, do: acc, else: [id | acc]
                    end)
                    |> Enum.sort()
                }
              }
            )
          ),
          %{"name" => "childrenColor", "value" => "black"},
          %{"name" => "leafColor", "value" => opts[:leaves][:fill]},
          %{"name" => "splitColor", "value" => opts[:splits][:fill]},
          %{"name" => "spaceBetweenLevels", "value" => opts[:space_between][:levels]},
          %{"name" => "spaceBetweenNodes", "value" => opts[:space_between][:nodes]},
          %{"name" => "nodeWidth", "value" => opts[:node_width]},
          %{"name" => "nodeHeight", "value" => opts[:node_height]},
          %{
            "name" => "startingDepth",
            "on" => [%{"events" => %{"throttle" => 0, "type" => "timer"}, "update" => "-1"}],
            "value" =>
              opts[:depth] ||
                to_tabular(booster)
                |> Enum.map(&Map.get(&1, "depth"))
                |> Enum.filter(& &1)
                |> Enum.max()
          },
          %{
            "name" => "node",
            "on" => [
              %{
                "events" => %{"markname" => "node", "type" => "click"},
                "update" => "datum.nodeid"
              }
            ],
            "value" => 0
          },
          %{
            "name" => "nodeHighlight",
            "on" => [
              %{
                "events" => %{"markname" => "node", "type" => "mouseover"},
                "update" => "pluck(treeAncestors('treeCalcs', datum.nodeid), 'nodeid')"
              },
              %{"events" => %{"type" => "mouseout"}, "update" => "[0]"}
            ],
            "value" => "[0]"
          },
          %{
            "name" => "isExpanded",
            "on" => [
              %{
                "events" => %{"markname" => "node", "type" => "click"},
                "update" =>
                  "datum.children > 0 && indata('treeClickStorePerm', 'nodeid', datum.childrenIds[0]) ? true : false"
              }
            ],
            "value" => 0
          },
          %{"name" => "xrange", "update" => "[0, width]"},
          %{"name" => "yrange", "update" => "[0, height]"},
          %{
            "name" => "down",
            "on" => [%{"events" => "mousedown", "update" => "xy()"}],
            "value" => nil
          },
          %{
            "name" => "xcur",
            "on" => [%{"events" => "mousedown", "update" => "slice(xdom)"}],
            "value" => nil
          },
          %{
            "name" => "ycur",
            "on" => [%{"events" => "mousedown", "update" => "slice(ydom)"}],
            "value" => nil
          },
          %{
            "name" => "delta",
            "on" => [
              %{
                "events" => [
                  %{
                    "between" => [
                      %{"type" => "mousedown"},
                      %{"source" => "window", "type" => "mouseup"}
                    ],
                    "consume" => true,
                    "source" => "window",
                    "type" => "mousemove"
                  }
                ],
                "update" => "down ? [down[0]-x(), down[1]-y()] : [0,0]"
              }
            ],
            "value" => [0, 0]
          },
          %{
            "name" => "anchor",
            "on" => [
              %{"events" => "wheel", "update" => "[invert('xscale', x()), invert('yscale', y())]"}
            ],
            "value" => [0, 0]
          },
          %{"name" => "xext", "update" => "[0,width]"},
          %{"name" => "yext", "update" => "[0,height]"},
          %{
            "name" => "zoom",
            "on" => [
              %{
                "events" => "wheel!",
                "force" => true,
                "update" => "pow(1.001, event.deltaY * pow(16, event.deltaMode))"
              }
            ],
            "value" => 1
          },
          %{
            "name" => "xdom",
            "on" => [
              %{
                "events" => %{"signal" => "delta"},
                "update" =>
                  "[xcur[0] + span(xcur) * delta[0] / width, xcur[1] + span(xcur) * delta[0] / width]"
              },
              %{
                "events" => %{"signal" => "zoom"},
                "update" =>
                  "[anchor[0] + (xdom[0] - anchor[0]) * zoom, anchor[0] + (xdom[1] - anchor[0]) * zoom]"
              }
            ],
            "update" => "slice(xext)"
          },
          %{
            "name" => "ydom",
            "on" => [
              %{
                "events" => %{"signal" => "delta"},
                "update" =>
                  "[ycur[0] + span(ycur) * delta[1] / height, ycur[1] + span(ycur) * delta[1] / height]"
              },
              %{
                "events" => %{"signal" => "zoom"},
                "update" =>
                  "[anchor[1] + (ydom[0] - anchor[1]) * zoom, anchor[1] + (ydom[1] - anchor[1]) * zoom]"
              }
            ],
            "update" => "slice(yext)"
          },
          %{"name" => "scaledNodeWidth", "update" => "(nodeWidth/ span(xdom))*width"},
          %{"name" => "scaledNodeHeight", "update" => "abs(nodeHeight/ span(ydom))*height"},
          %{"name" => "scaledLimit", "update" => "(20/ span(xdom))*width"},
          %{
            "name" => "leavesFontSize",
            "update" => "(#{opts[:leaves][:font_size]}/ span(xdom))*width"
          },
          %{
            "name" => "splitsFontSize",
            "update" => "(#{opts[:splits][:font_size]}/ span(xdom))*width"
          },
          %{
            "name" => "linksFontSize",
            "update" => "(#{opts[:links][:font_size]}/ span(xdom))*width"
          }
        ]
      })

    spec = Map.merge(spec, tlk)
    spec = (opts[:validate] && validate_spec(spec)) || spec

    Jason.encode!(spec) |> VegaLite.from_json()
  end

  # Helpers (from https://github.com/livebook-dev/vega_lite/blob/v0.1.8/lib/vega_lite.ex#L1094)

  defp opts_to_vl_props(opts) do
    opts |> Map.new() |> to_vl()
  end

  defp to_vl(value) when value in [true, false, nil], do: value

  defp to_vl(atom) when is_atom(atom), do: to_vl_key(atom)

  defp to_vl(%_{} = struct), do: struct

  defp to_vl(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl([{key, _} | _] = keyword) when is_atom(key) do
    Map.new(keyword, fn {key, value} ->
      {to_vl(key), to_vl(value)}
    end)
  end

  defp to_vl(list) when is_list(list) do
    Enum.map(list, &to_vl/1)
  end

  defp to_vl(value), do: value

  defp to_vl_key(key) when is_atom(key) do
    key |> to_string() |> snake_to_camel()
  end

  defp snake_to_camel(string) do
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part, :ascii) | Enum.map(parts, &capitalize/1)])
  end

  defp capitalize(<<first, rest::binary>>) when first in ?a..?z, do: <<first - 32, rest::binary>>
  defp capitalize(rest), do: rest
end

defimpl Kino.Render, for: EXGBoost.Booster do
  def to_livebook(booster) do
    EXGBoost.Plotting.to_vega(booster) |> Kino.Render.to_livebook()
  end
end
