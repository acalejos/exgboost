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
    leafs: [
      doc: "Specifies characteristics of leaf nodes",
      type: :keyword_list,
      default: [fill: "#ccc", stroke: "black", strokeWidth: 1]
    ],
    inner_nodes: [
      doc: "Specifies characteristics of inner nodes",
      type: :boolean,
      default: true
    ],
    links: [
      doc: "Specifies characteristics of links between nodes",
      type: :keyword_list,
      default: [stroke: "#ccc", strokeWidth: 1]
    ],
    validate: [
      doc: "Whether to validate the Vega specification against the Vega schema",
      type: :boolean,
      default: true
    ],
    index: [
      doc:
        "The zero-indexed index of the tree to plot. If `nil`, plots all trees using a dropdown selector to switch between trees",
      type: {:or, [nil, :pos_integer]},
      default: 0
    ]
  ]

  @plotting_schema NimbleOptions.new!(@plotting_params)

  def get_schema(), do: @schema

  defp validate_spec(spec) do
    unless Code.ensure_loaded?(EXJsonSchema) do
      raise(
        RuntimeError,
        "The `ex_json_schema` package must be installed to validate Vega specifications. Please install it by running `mix deps.get`"
      )
    end

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
    node = new_node(node)

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
        %{
          "name" => "tree",
          "values" => to_tabular(booster),
          "transform" => [
            %{
              "type" => "stratify",
              "key" => "nodeid",
              "parentKey" => "parentid"
            },
            %{
              "type" => "tree",
              "size" => [%{"signal" => "width"}, %{"signal" => "height"}],
              "as" => ["x", "y", "depth", "children"]
            },
            %{
              "type" => "filter",
              "expr" => "datum.tree_id === selectedTree"
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
      ]
    }
  end

  def to_vega(booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @plotting_schema) |> opts_to_vl_props()
    spec = get_data_spec(booster)
    spec = Map.merge(spec, opts)

    spec = %{
      spec
      | "scales" => [
          %{
            "name" => "color",
            "type" => "ordinal",
            "domain" => %{"data" => "tree", "field" => "depth"},
            "range" => %{"scheme" => "category10"}
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
          )
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
    Kino.Render.to_livebook(EXGBoost.Plotting.to_vega(booster) |> Kino.Render.to_livebook())
  end
end
