defmodule EXGBoost.Plotting do
  use EXGBoost.Plotting.Style

  @doc """
  A light theme based on the [Solarized](https://ethanschoonover.com/solarized/) color palette
  """
  style :solarized_light do
    [
      # base3
      background: "#fdf6e3",
      leaves: [
        # base01
        text: [fill: "#586e75", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        # base2, base1
        rect: [fill: "#eee8d5", stroke: "#93a1a1", strokeWidth: 1]
      ],
      splits: [
        # base01
        text: [fill: "#586e75", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        # base1, base00
        rect: [fill: "#93a1a1", stroke: "#657b83", strokeWidth: 1],
        # base00
        children: [fill: "#657b83", stroke: "#657b83", strokeWidth: 1]
      ],
      yes: [
        # green
        text: [fill: "#859900"],
        # base00
        path: [stroke: "#657b83", strokeWidth: 1]
      ],
      no: [
        # red
        text: [fill: "#dc322f"],
        # base00
        path: [stroke: "#657b83", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A dark theme based on the [Solarized](https://ethanschoonover.com/solarized/) color palette
  """
  style :solarized_dark do
    # base03
    [
      background: "#002b36",
      leaves: [
        # base0
        text: [fill: "#839496", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        # base02, base01
        rect: [fill: "#073642", stroke: "#586e75", strokeWidth: 1]
      ],
      splits: [
        # base0
        text: [fill: "#839496", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        # base01, base00
        rect: [fill: "#586e75", stroke: "#657b83", strokeWidth: 1],
        # base00
        children: [fill: "#657b83", stroke: "#657b83", strokeWidth: 1]
      ],
      yes: [
        # green
        text: [fill: "#859900"],
        # base00
        path: [stroke: "#657b83", strokeWidth: 1]
      ],
      no: [
        # red
        text: [fill: "#dc322f"],
        # base00
        path: [stroke: "#657b83", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A light and playful theme
  """
  style :playful_light do
    [
      background: "#f0f0f0",
      padding: 10,
      leaves: [
        text: [fill: "#000", font_size: 12, font_style: "italic", font_weight: "bold"],
        rect: [fill: "#e91e63", stroke: "#000", stroke_width: 1, radius: 5]
      ],
      splits: [
        text: [fill: "#000", font_size: 12, font_style: "normal", font_weight: "bold"],
        children: [
          fill: "#000",
          font_size: 12,
          font_style: "normal",
          font_weight: "bold"
        ],
        rect: [fill: "#8bc34a", stroke: "#000", stroke_width: 1, radius: 10]
      ],
      yes: [
        path: [stroke: "#4caf50", stroke_width: 2]
      ],
      no: [
        path: [stroke: "#f44336", stroke_width: 2]
      ]
    ]
  end

  @doc """
  A dark and playful theme
  """
  style :playful_dark do
    [
      background: "#333",
      padding: 10,
      leaves: [
        text: [fill: "#fff", font_size: 12, font_style: "italic", font_weight: "bold"],
        rect: [fill: "#e91e63", stroke: "#fff", stroke_width: 1, radius: 5]
      ],
      splits: [
        text: [fill: "#fff", font_size: 12, font_style: "normal", font_weight: "bold"],
        rect: [fill: "#8bc34a", stroke: "#fff", stroke_width: 1, radius: 10]
      ],
      yes: [
        text: [fill: "#4caf50"],
        path: [stroke: "#4caf50", stroke_width: 2]
      ],
      no: [
        text: [fill: "#f44336"],
        path: [stroke: "#f44336", stroke_width: 2]
      ]
    ]
  end

  @doc """
  A dark theme
  """
  style :dark do
    [
      background: "#333",
      padding: 10,
      leaves: [
        text: [fill: "#fff", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#666", stroke: "#fff", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#fff", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#444", stroke: "#fff", strokeWidth: 1],
        children: [fill: "#fff", stroke: "#fff", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A high contrast theme
  """
  style :high_contrast do
    [
      background: "#000",
      padding: 10,
      leaves: [
        text: [fill: "#fff", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#333", stroke: "#fff", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#fff", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#666", stroke: "#fff", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A light theme
  """
  style :light do
    [
      background: "#f0f0f0",
      padding: 10,
      leaves: [
        text: [fill: "#000", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#ddd", stroke: "#000", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#000", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#bbb", stroke: "#000", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A theme based on the [Monokai](https://monokai.pro/) color palette
  """
  style :monokai do
    [
      background: "#272822",
      leaves: [
        text: [fill: "#f8f8f2", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#3e3d32", stroke: "#66d9ef", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#f8f8f2", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#66d9ef", stroke: "#f8f8f2", strokeWidth: 1],
        children: [fill: "#f8f8f2", stroke: "#f8f8f2", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#a6e22e"],
        path: [stroke: "#f8f8f2", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#f92672"],
        path: [stroke: "#f8f8f2", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A theme based on the [Dracula](https://draculatheme.com/) color palette
  """
  style :dracula do
    [
      background: "#282a36",
      leaves: [
        text: [fill: "#f8f8f2", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#44475a", stroke: "#ff79c6", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#f8f8f2", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#ff79c6", stroke: "#f8f8f2", strokeWidth: 1],
        children: [fill: "#f8f8f2", stroke: "#f8f8f2", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#50fa7b"],
        path: [stroke: "#f8f8f2", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#ff5555"],
        path: [stroke: "#f8f8f2", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A theme based on the [Nord](https://www.nordtheme.com/) color palette
  """
  style :nord do
    [
      background: "#2e3440",
      leaves: [
        text: [fill: "#d8dee9", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#3b4252", stroke: "#88c0d0", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#d8dee9", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#88c0d0", stroke: "#d8dee9", strokeWidth: 1],
        children: [fill: "#d8dee9", stroke: "#d8dee9", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#a3be8c"],
        path: [stroke: "#d8dee9", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#bf616a"],
        path: [stroke: "#d8dee9", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A theme based on the [Material](https://material.io/design/color/the-color-system.html#tools-for-picking-colors) color palette
  """
  style :material do
    [
      background: "#263238",
      leaves: [
        text: [fill: "#eceff1", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#37474f", stroke: "#80cbc4", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#eceff1", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#80cbc4", stroke: "#eceff1", strokeWidth: 1],
        children: [fill: "#eceff1", stroke: "#eceff1", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#c5e1a5"],
        path: [stroke: "#eceff1", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#ef9a9a"],
        path: [stroke: "#eceff1", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A theme based on the One Dark color palette
  """
  style :one_dark do
    [
      background: "#282c34",
      leaves: [
        text: [fill: "#abb2bf", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#3b4048", stroke: "#98c379", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#abb2bf", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#98c379", stroke: "#abb2bf", strokeWidth: 1],
        children: [fill: "#abb2bf", stroke: "#abb2bf", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#98c379"],
        path: [stroke: "#abb2bf", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#e06c75"],
        path: [stroke: "#abb2bf", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A theme based on the [Gruvbox](https://github.com/morhetz/gruvbox) color palette
  """
  style :gruvbox do
    [
      background: "#282828",
      leaves: [
        text: [fill: "#ebdbb2", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#3c3836", stroke: "#b8bb26", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#ebdbb2", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#b8bb26", stroke: "#ebdbb2", strokeWidth: 1],
        children: [fill: "#ebdbb2", stroke: "#ebdbb2", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#b8bb26"],
        path: [stroke: "#ebdbb2", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#fb4934"],
        path: [stroke: "#ebdbb2", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A dark theme based on the [Horizon](https://www.horizon.io/) color palette
  """
  style :horizon_dark do
    [
      background: "#1C1E26",
      leaves: [
        text: [fill: "#E3E6EE", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#232530", stroke: "#F43E5C", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#E3E6EE", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#F43E5C", stroke: "#E3E6EE", strokeWidth: 1],
        children: [fill: "#E3E6EE", stroke: "#E3E6EE", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#48B685"],
        path: [stroke: "#E3E6EE", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#F43E5C"],
        path: [stroke: "#E3E6EE", strokeWidth: 1]
      ]
    ]
  end

  @doc """
  A light theme based on the [Horizon](https://www.horizon.io/) color palette
  """
  style :horizon_light do
    [
      background: "#FDF0ED",
      leaves: [
        text: [fill: "#1A2026", fontSize: 12, fontStyle: "normal", fontWeight: "normal"],
        rect: [fill: "#F7E3D3", stroke: "#F43E5C", strokeWidth: 1]
      ],
      splits: [
        text: [fill: "#1A2026", fontSize: 12, fontStyle: "normal", fontWeight: "bold"],
        rect: [fill: "#F43E5C", stroke: "#1A2026", strokeWidth: 1],
        children: [fill: "#1A2026", stroke: "#1A2026", strokeWidth: 1]
      ],
      yes: [
        text: [fill: "#48B685"],
        path: [stroke: "#1A2026", strokeWidth: 1]
      ],
      no: [
        text: [fill: "#F43E5C"],
        path: [stroke: "#1A2026", strokeWidth: 1]
      ]
    ]
  end

  HTTPoison.start()

  @schema HTTPoison.get!("https://vega.github.io/schema/vega/v5.json").body
          |> Jason.decode!()
          |> ExJsonSchema.Schema.resolve()

  @mark_text_doc "Accepts a keyword list of Vega `text` Mark properties. Reference [here](https://vega.github.io/vega/docs/marks/text/) for more details. Accepts either a string (expected to be valid Vega property names) or Elixir-styled atom. Note that keys are snake-cased instead of camel-case (e.g. Vega `fontSize` becomes `font_size`)"
  @mark_rect_doc "Accepts a keyword list of Vega `rect` Mark properties. Reference [here](https://vega.github.io/vega/docs/marks/rect/) for more details. Accepts either a string (expected to be valid Vega property names) or Elixir-styled atom. Note that keys are snake-cased instead of camel-case (e.g. Vega `fontSize` becomes `font_size`)"
  @mark_path_doc "Accepts a keyword list of Vega `path` Mark properties. Reference [here](https://vega.github.io/vega/docs/marks/path/) for more details. Accepts either a string (expected to be valid Vega property names) or Elixir-styled atom. Note that keys are snake-cased instead of camel-case (e.g. Vega `fontSize` becomes `font_size`)"

  @mark_opts [
    type: :keyword_list,
    keys: [
      *: [type: {:or, [:string, :atom, :integer, :boolean, nil, {:list, :any}]}]
    ]
  ]

  @default_leaf_text [
    align: :center,
    baseline: :middle,
    font_size: 13,
    font: "Calibri"
  ]

  @default_leaf_rect [
    corner_radius: 2,
    opacity: 1
  ]

  @default_split_text [
    align: :center,
    baseline: :middle,
    font_size: 13,
    font: "Calibri"
  ]

  @default_split_rect [
    corner_radius: 2,
    opacity: 1
  ]

  @default_split_children [
    align: :right,
    baseline: :middle,
    font: "Calibri",
    font_size: 13
  ]

  @default_yes_path []

  @default_yes_text [
    align: :center,
    baseline: :middle,
    font_size: 13,
    font: "Calibri",
    text: "yes"
  ]

  @default_no_path []

  @default_no_text [
    align: :center,
    baseline: :middle,
    font_size: 13,
    font: "Calibri",
    text: "no"
  ]

  @plotting_params [
    style: [
      doc:
        "The style to use for the visualization. Refer to `EXGBoost.Plotting.Styles` for a list of available styles.",
      default: Application.compile_env(:exgboost, [:plotting, :style], :dracula),
      type: {:or, [{:in, Keyword.keys(@styles)}, {:in, [nil, false]}, :keyword_list]}
    ],
    rankdir: [
      doc: "Determines the direction of the graph.",
      type: {:in, [:tb, :lr, :bt, :rl]},
      default: Application.compile_env(:exgboost, [:plotting, :rankdir], :tb)
    ],
    autosize: [
      doc:
        "Determines if the visualization should automatically resize when the window size changes",
      type: {:in, ["fit", "pad", "fit-x", "fit-y", "none"]},
      default: Application.compile_env(:exgboost, [:plotting, :autosize], "fit")
    ],
    background: [
      doc:
        "The background color of the visualization. Accepts a valid CSS color string. For example: `#f304d3`, `#ccc`, `rgb(253, 12, 134)`, `steelblue.`",
      type: :string,
      default: Application.compile_env(:exgboost, [:plotting, :background], "#f5f5f5")
    ],
    height: [
      doc: "Height of the plot in pixels",
      type: :pos_integer,
      default: Application.compile_env(:exgboost, [:plotting, :height], 400)
    ],
    width: [
      doc: "Width of the plot in pixels",
      type: :pos_integer,
      default: Application.compile_env(:exgboost, [:plotting, :width], 600)
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
      default: Application.compile_env(:exgboost, [:plotting, :padding], 30)
    ],
    leaves: [
      doc: "Specifies characteristics of leaf nodes",
      type: :keyword_list,
      keys: [
        text:
          @mark_opts ++
            [
              doc: @mark_text_doc,
              default:
                deep_merge_kw(
                  @default_leaf_text,
                  Application.compile_env(
                    :exgboost,
                    [:plotting, :leaves, :text],
                    []
                  )
                )
            ],
        rect:
          @mark_opts ++
            [
              doc: @mark_rect_doc,
              default:
                deep_merge_kw(
                  @default_leaf_rect,
                  Application.compile_env(
                    :exgboost,
                    [:plotting, :leaves, :rect],
                    []
                  )
                )
            ]
      ],
      default: [
        text:
          deep_merge_kw(
            @default_leaf_text,
            Application.compile_env(:exgboost, [:plotting, :leaves, :text], [])
          ),
        rect:
          deep_merge_kw(
            @default_leaf_rect,
            Application.compile_env(:exgboost, [:plotting, :leaves, :rect], [])
          )
      ]
    ],
    splits: [
      doc: "Specifies characteristics of split nodes",
      type: :keyword_list,
      keys: [
        text:
          @mark_opts ++
            [
              doc: @mark_text_doc,
              default:
                deep_merge_kw(
                  @default_split_text,
                  Application.compile_env(
                    :exgboost,
                    [:plotting, :splits, :text],
                    []
                  )
                )
            ],
        rect:
          @mark_opts ++
            [
              doc: @mark_rect_doc,
              default:
                deep_merge_kw(
                  @default_split_rect,
                  Application.compile_env(
                    :exgboost,
                    [:plotting, :splits, :rect],
                    []
                  )
                )
            ],
        children:
          @mark_opts ++
            [
              doc: @mark_text_doc,
              default:
                deep_merge_kw(
                  @default_split_children,
                  Application.compile_env(
                    :exgboost,
                    [:plotting, :splits, :children],
                    []
                  )
                )
            ]
      ],
      default: [
        text:
          deep_merge_kw(
            @default_split_text,
            Application.compile_env(:exgboost, [:plotting, :splits, :text], [])
          ),
        rect:
          deep_merge_kw(
            @default_split_rect,
            Application.compile_env(:exgboost, [:plotting, :splits, :rect], [])
          ),
        children:
          deep_merge_kw(
            @default_split_children,
            Application.compile_env(
              :exgboost,
              [:plotting, :splits, :children],
              []
            )
          )
      ]
    ],
    node_width: [
      doc: "The width of each node in pixels",
      type: :pos_integer,
      default: Application.compile_env(:exgboost, [:plotting, :node_width], 100)
    ],
    node_height: [
      doc: "The height of each node in pixels",
      type: :pos_integer,
      default: Application.compile_env(:exgboost, [:plotting, :node_heigh], 45)
    ],
    space_between: [
      doc: "The space between the rectangular marks in pixels.",
      type: :keyword_list,
      keys: [
        nodes: [
          doc: "Space between marks within the same depth of the tree.",
          type: :pos_integer,
          default: Application.compile_env(:exgboost, [:plotting, :space_between, :nodes], 10)
        ],
        levels: [
          doc: "Space between each rank / depth of the tree.",
          type: :pos_integer,
          default: Application.compile_env(:exgboost, [:plotting, :space_between, :levels], 100)
        ]
      ],
      default: [
        nodes: Application.compile_env(:exgboost, [:plotting, :space_between, :nodes], 10),
        levels: Application.compile_env(:exgboost, [:plotting, :space_between, :levels], 100)
      ]
    ],
    yes: [
      doc: "Specifies characteristics of links between nodes where the split condition is true",
      type: :keyword_list,
      keys: [
        path:
          @mark_opts ++
            [
              doc: @mark_path_doc,
              default:
                deep_merge_kw(
                  @default_yes_path,
                  Application.compile_env(:exgboost, [:plotting, :yes, :path], [])
                )
            ],
        text:
          @mark_opts ++
            [
              doc: @mark_text_doc,
              default:
                deep_merge_kw(
                  @default_yes_text,
                  Application.compile_env(:exgboost, [:plotting, :yes, :text], [])
                )
            ]
      ],
      default: [
        path:
          deep_merge_kw(
            @default_yes_path,
            Application.compile_env(:exgboost, [:plotting, :yes, :path], [])
          ),
        text:
          deep_merge_kw(
            @default_yes_text,
            Application.compile_env(:exgboost, [:plotting, :yes, :text], [])
          )
      ]
    ],
    no: [
      doc: "Specifies characteristics of links between nodes where the split condition is false",
      type: :keyword_list,
      keys: [
        path:
          @mark_opts ++
            [
              doc: @mark_path_doc,
              default:
                deep_merge_kw(
                  @default_no_path,
                  Application.compile_env(:exgboost, [:plotting, :no, :path], [])
                )
            ],
        text:
          @mark_opts ++
            [
              doc: @mark_text_doc,
              default:
                deep_merge_kw(
                  @default_no_text,
                  Application.compile_env(:exgboost, [:plotting, :no, :path], [])
                )
            ]
      ],
      default: [
        path:
          deep_merge_kw(
            @default_no_path,
            Application.compile_env(:exgboost, [:plotting, :no, :path], [])
          ),
        text:
          deep_merge_kw(
            @default_no_text,
            Application.compile_env(:exgboost, [:plotting, :no, :path], [])
          )
      ]
    ],
    validate: [
      doc: "Whether to validate the Vega specification against the Vega schema",
      type: :boolean,
      default: Application.compile_env(:exgboost, [:plotting, :validate], true)
    ],
    index: [
      doc:
        "The zero-indexed index of the tree to plot. If `nil`, plots all trees using a dropdown selector to switch between trees",
      type: {:or, [nil, :non_neg_integer]},
      default: Application.compile_env(:exgboost, [:plotting, :index], 0)
    ],
    depth: [
      doc:
        "The depth of the tree to plot. If `nil`, plots all levels (cick on a node to expand/collapse)",
      type: {:or, [nil, :non_neg_integer]},
      default: Application.compile_env(:exgboost, [:plotting, :depth], nil)
    ]
  ]

  @plotting_schema NimbleOptions.new!(@plotting_params)
  @defaults NimbleOptions.validate!([], @plotting_schema)

  @moduledoc """
  Functions for plotting EXGBoost `Booster` models using [Vega](https://vega.github.io/vega/)

  Fundamentally, all this module does is convert a `Booster` into a format that can be
  ingested by Vega, and apply some default configuations that only account for a subset of the configurations
  that can be set by a Vega spec directly. The functions provided in this module are designed to have opinionated
  defaults that can be used to quickly visualize a model, but the full power of Vega is available by using the
  `to_tabular/1` function to convert the model into a tabular format, and then using the `plot/2` function
  to convert the tabular format into a Vega specification.

  ## Default Vega Specification

  The default Vega specification is designed to be a good starting point for visualizing a model, but it is
  possible to customize the specification by passing in a map of Vega properties to the `plot/2` function.
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
  possible to customize the specification by passing in a map of Vega properties to the `plot/2` function.
  You can find the full list of Vega properties [here](https://vega.github.io/vega/docs/specification/).

  It is suggested that you use the data attributes provided by the default specification as a starting point, since they
  provide the necessary data transformation to convert the model into a tree structure that can be visualized by Vega.
  If you would like to customize the default specification, you can use `EXGBoost.Plotting.plot/1` to get the default
  specification, and then modify it as needed.

  Once you have a custom specification, you can pass it to `VegaLite.from_json/1` to create a new `VegaLite` struct, after which
  you can use the functions provided by the `VegaLite` module to render the model.

  ## Specification Validation
  You can optionally validate your specification against the Vega schema by passing the `validate: true` option to `plot/2`.
  This will raise an error if the specification is invalid. This is useful if you are creating a custom specification and want
  to ensure that it is valid. Note that this will only validate the specification against the Vega schema, and not against the
  VegaLite schema. This requires the [`ex_json_schema`] package to be installed.

  ## Livebook Integration

  This module also provides a `Kino.Render` implementation for `EXGBoost.Booster` which allows
  models to be rendered directly in Livebook. This is done by converting the model into a Vega specification
  and then using the `Kino.Render` implementation for Elixir's [`VegaLite`](https://hexdocs.pm/vega_lite/VegaLite.html) API
  to render the model.

  . The Vega specification is then passed to [VegaLite](https://hexdocs.pm/vega_lite/readme.html)

  ## Plotting Parameters

  This module exposes a high-level API for customizing the EXGBoost model visualization, but it is also possible to
  customize the Vega specification directly. You can also choose to pass in Vega Mark specifications to customize the
  appearance of the nodes and links in the visualization outside of the parameteres specified below. Refer to the
  [Vega documentation](https://vega.github.io/vega/docs/marks/) for more details on how to do this.

  #{NimbleOptions.docs(@plotting_params)}


  ## Styles

  Styles are a keyword-map that adhere to the plotting schema as defined in `EXGBoost.Plotting`.
  `EXGBoost.Plotting.Styles` provides a set of predefined styles that can be used to quickly customize the appearance of the visualization.


  Refer to the `EXGBoost.Plotting.Styles` module for a list of available styles. You can pass a style to the `:style`
  option as an atom or string, and it will be applied to the visualization. Styles will override any other options that are passed
  for each option where the style defined a value. For example, if you pass `:solarized_light` as the style, and also pass
  `:background` as an option, the `:background` option will be ignored since the `:solarized_light` style defines its own value for `:background`.
  """

  @spec get_schema() :: ExJsonSchema.Schema.Root.t()
  def get_schema(), do: @schema

  @spec get_defaults() :: Keyword.t()
  def get_defaults(), do: @defaults

  @spec get_styles() :: [{atom(), [style(), ...]}, ...]
  def get_styles(), do: @styles

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
  - depth: The depth of the node (root node is depth 1)
  - leaf: The leaf value if it is a leaf node
  """
  @spec to_tabular(EXGBoost.Booster.t()) :: [map()]
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

  ## Options

  * `:rankdir` - Determines the direction of the graph. Accepts one of `:tb`, `:lr`, `:bt`, or `:rl`. Defaults to `:tb`

  """
  @spec get_data_spec(booster :: EXGBoost.Booster.t(), opts :: keyword()) :: map()
  def get_data_spec(booster, opts \\ []) do
    opts = NimbleOptions.validate!(opts, @plotting_schema)

    opts =
      cond do
        opts[:style] in [nil, false] ->
          opts

        Keyword.keyword?(opts[:style]) ->
          deep_merge_kw(opts[:style], opts, @defaults)

        true ->
          style = apply(__MODULE__, opts[:style], [])
          deep_merge_kw(style, opts, @defaults)
      end
      |> then(&deep_merge_kw(@defaults, &1))

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
              "as" =>
                case opts[:rankdir] do
                  vertical when vertical in [:tb, :bt] ->
                    ["x", "y", "depth", "children"]

                  horizontal when horizontal in [:lr, :rl] ->
                    ["y", "x", "depth", "children"]
                end,
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
              "as" =>
                case opts[:rankdir] do
                  vertical when vertical in [:tb, :bt] ->
                    ["x", "y", "depth", "children"]

                  horizontal when horizontal in [:lr, :rl] ->
                    ["y", "x", "depth", "children"]
                end,
              "method" => "tidy",
              "nodeSize" => [
                %{"signal" => "nodeWidth + spaceBetweenNodes"},
                %{"signal" => "nodeHeight+ spaceBetweenLevels"}
              ],
              "separation" => %{"signal" => "false"},
              "type" => "tree"
            },
            %{
              "as" => "y",
              "expr" => "#{if opts[:rankdir] == :bt, do: -1, else: 1}*(datum.y+(height/10))",
              "type" => "formula"
            },
            %{
              "as" => "x",
              "expr" => "#{if opts[:rankdir] == :rl, do: -1, else: 1}*(datum.x+(width/2))",
              "type" => "formula"
            },
            %{"type" => "extent", "field" => "x", "signal" => "x_extent"},
            %{"type" => "extent", "field" => "y", "signal" => "y_extent"},
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
          "name" => "splitNodes",
          "source" => "fullTreeLayout",
          "transform" => [
            %{
              "type" => "filter",
              "expr" => "indata('treeClickStorePerm', 'nodeid', datum.nodeid) && datum.isLeaf"
            }
          ]
        },
        %{
          "name" => "leafNodes",
          "source" => "fullTreeLayout",
          "transform" => [
            %{
              "type" => "filter",
              "expr" => "indata('treeClickStorePerm', 'nodeid', datum.nodeid) && !datum.isLeaf"
            }
          ]
        },
        %{
          "name" => "links",
          "source" => "treeLayout",
          "transform" => [
            %{"type" => "treelinks"},
            %{
              "orient" =>
                case opts[:rankdir] do
                  vertical when vertical in [:tb, :bt] ->
                    "vertical"

                  horizontal when horizontal in [:lr, :rl] ->
                    "horizontal"
                end,
              "shape" => "line",
              "sourceX" => %{
                "expr" =>
                  case opts[:rankdir] do
                    vertical when vertical in [:tb, :bt] ->
                      "scale('xscale', datum.source.x)"

                    :lr ->
                      "scale('xscale', datum.source.x) + scaledNodeWidth/2"

                    :rl ->
                      "scale('xscale', datum.source.x) - scaledNodeWidth/2"
                  end
              },
              "sourceY" => %{
                "expr" =>
                  case opts[:rankdir] do
                    vertical when vertical in [:tb, :bt] ->
                      "scale('yscale', datum.source.y)"

                    horizontal when horizontal in [:lr, :rl] ->
                      "scale('yscale', datum.source.y) - scaledNodeHeight/2"
                  end
              },
              "targetX" => %{
                "expr" =>
                  case opts[:rankdir] do
                    vertical when vertical in [:tb, :bt] ->
                      "scale('xscale', datum.target.x)"

                    :lr ->
                      "scale('xscale', datum.target.x) - scaledNodeWidth/2"

                    :rl ->
                      "scale('xscale', datum.target.x) + scaledNodeWidth/2"
                  end
              },
              "targetY" => %{
                "expr" =>
                  case opts[:rankdir] do
                    vertical when vertical in [:tb, :bt] ->
                      "scale('yscale', datum.target.y) - scaledNodeHeight"

                    horizontal when horizontal in [:lr, :rl] ->
                      "scale('yscale', datum.target.y) - scaledNodeHeight/2"
                  end
              },
              "type" => "linkpath"
            },
            %{
              "expr" => " indata('treeClickStorePerm', 'nodeid', datum.target.nodeid)",
              "type" => "filter"
            }
          ]
        },
        %{
          "name" => "yesPaths",
          "source" => "links",
          "transform" => [
            %{
              "type" => "filter",
              "expr" => "datum.source.yes === datum.target.nodeid "
            }
          ]
        },
        %{
          "name" => "noPaths",
          "source" => "links",
          "transform" => [
            %{
              "type" => "filter",
              "expr" => "datum.source.yes !== datum.target.nodeid "
            }
          ]
        }
      ]
    }
  end

  @spec plot(EXGBoost.Booster.t(), Keyword.t()) :: VegaLite.t()
  def plot(booster, opts \\ []) do
    spec = get_data_spec(booster, opts)
    opts = NimbleOptions.validate!(opts, @plotting_schema)

    opts =
      cond do
        opts[:style] in [nil, false] ->
          opts

        Keyword.keyword?(opts[:style]) ->
          deep_merge_kw(opts[:style], opts, @defaults)

        true ->
          style = apply(__MODULE__, opts[:style], [])
          deep_merge_kw(style, opts, @defaults)
      end
      |> then(&deep_merge_kw(@defaults, &1))

    # Try to account for non-default node height / width to adjust spacing
    # between nodes and levels as a quality of life improvement
    # If they provide their own spacing, don't adjust it
    opts =
      cond do
        opts[:rankdir] in [:lr, :rl] and
            opts[:space_between][:levels] == @defaults[:space_between][:levels] ->
          put_in(
            opts[:space_between][:levels],
            @defaults[:space_between][:levels] + (opts[:node_width] - @defaults[:node_width])
          )

        opts[:rankdir] in [:tb, :bt] and
            opts[:space_between][:levels] == @defaults[:space_between][:levels] ->
          put_in(
            opts[:space_between][:levels],
            @defaults[:space_between][:levels] + (opts[:node_height] - @defaults[:node_height])
          )

        true ->
          opts
      end

    opts =
      cond do
        opts[:rankdir] in [:lr, :rl] and
            opts[:space_between][:nodes] == @defaults[:space_between][:nodes] ->
          put_in(
            opts[:space_between][:nodes],
            @defaults[:space_between][:nodes] + (opts[:node_height] - @defaults[:node_height])
          )

        opts[:rankdir] in [:tb, :bt] and
            opts[:space_between][:nodes] == @defaults[:space_between][:nodes] ->
          put_in(
            opts[:space_between][:nodes],
            @defaults[:space_between][:nodes] + (opts[:node_width] - @defaults[:node_width])
          )

        true ->
          opts
      end

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
            "encode" =>
              Map.merge(
                %{
                  "update" => %{
                    "path" => %{"field" => "path"},
                    "strokeWidth" => %{
                      "signal" => "indexof(nodeHighlight, datum.target.nodeid)> -1? 2:1"
                    }
                  }
                },
                format_mark(opts[:yes][:path])
              ),
            "from" => %{"data" => "yesPaths"},
            "interactive" => false,
            "type" => "path"
          },
          %{
            "encode" => %{
              "update" =>
                Map.merge(
                  %{
                    "path" => %{"field" => "path"},
                    "strokeWidth" => %{
                      "signal" => "indexof(nodeHighlight, datum.target.nodeid)> -1? 2:1"
                    }
                  },
                  format_mark(opts[:no][:path])
                )
            },
            "from" => %{"data" => "noPaths"},
            "interactive" => false,
            "type" => "path"
          },
          %{
            "encode" => %{
              "update" =>
                deep_merge_maps(
                  %{
                    "x" => %{
                      "signal" =>
                        "(scale('xscale', datum.source.x#{cond do
                          opts[:rankdir] in [:tb, :bt, :lr] -> ~c"-nodeWidth/4"
                          opts[:rankdir] in [:rl] -> ~c"+nodeWidth/4"
                          true -> ~c""
                        end}) + scale('xscale', datum.target.x)) / 2"
                    },
                    "y" => %{
                      "signal" =>
                        "(scale('yscale', datum.source.y#{if opts[:rankdir] in [:lr, :rl], do: ~c"-nodeWidth/3", else: ~c""}) + scale('yscale', datum.target.y)) / 2 - (scaledNodeHeight/2)"
                    }
                  },
                  format_mark(opts[:yes][:text])
                )
            },
            "from" => %{"data" => "yesPaths"},
            "type" => "text"
          },
          %{
            "encode" => %{
              "update" =>
                Map.merge(
                  %{
                    "x" => %{
                      "signal" =>
                        "(scale('xscale', datum.source.x#{cond do
                          opts[:rankdir] in [:tb, :bt, :lr] -> ~c"-nodeWidth/4"
                          opts[:rankdir] in [:rl] -> ~c"+nodeWidth/4"
                          true -> ~c""
                        end}) + scale('xscale', datum.target.x)) / 2"
                    },
                    "y" => %{
                      "signal" =>
                        "(scale('yscale', datum.source.y) + scale('yscale', datum.target.y)) / 2 - (scaledNodeHeight/2)"
                    }
                  },
                  format_mark(opts[:no][:text])
                )
            },
            "from" => %{"data" => "noPaths"},
            "type" => "text"
          },
          %{
            "clip" => false,
            "encode" => %{
              "update" =>
                Map.merge(
                  %{
                    "cursor" => %{"signal" => "datum.children > 0 ? 'pointer' : '' "},
                    "height" => %{"signal" => "scaledNodeHeight"},
                    "tooltip" => %{"signal" => ""},
                    "width" => %{"signal" => "scaledNodeWidth"},
                    "x" => %{"signal" => "datum.xscaled - (scaledNodeWidth / 2)"},
                    "yc" => %{"signal" => "scale('yscale',datum.y) - (scaledNodeHeight/2)"}
                  },
                  format_mark(opts[:splits][:rect])
                )
            },
            "from" => %{"data" => "splitNodes"},
            "name" => "splitNode",
            "marks" => [
              %{
                "encode" => %{
                  "update" =>
                    Map.merge(
                      %{
                        "limit" => %{"signal" => "scaledNodeWidth-scaledLimit"},
                        "text" => %{
                          "signal" =>
                            "parent.split + ' <= ' + format(parent.split_condition, '.2f')"
                        },
                        "x" => %{"signal" => "(scaledNodeWidth / 2)"},
                        "y" => %{"signal" => "scaledNodeHeight / 2"}
                      },
                      format_mark(opts[:splits][:text])
                    )
                },
                "interactive" => false,
                "name" => "title",
                "type" => "text"
              },
              %{
                "encode" => %{
                  "update" =>
                    Map.merge(
                      %{
                        "text" => %{"signal" => "parent.children"},
                        "x" => %{"signal" => "item.mark.group.width - (9/ span(xdom))*width"},
                        "y" => %{"signal" => "item.mark.group.height/2"}
                      },
                      format_mark(opts[:splits][:children])
                    )
                },
                "interactive" => false,
                "type" => "text"
              }
            ],
            "type" => "group"
          },
          %{
            "clip" => false,
            "encode" => %{
              "update" =>
                Map.merge(
                  %{
                    "cursor" => %{"signal" => "datum.children > 0 ? 'pointer' : '' "},
                    "height" => %{"signal" => "scaledNodeHeight"},
                    "tooltip" => %{"signal" => ""},
                    "width" => %{"signal" => "scaledNodeWidth"},
                    "x" => %{"signal" => "datum.xscaled - (scaledNodeWidth / 2)"},
                    "yc" => %{"signal" => "scale('yscale',datum.y) - (scaledNodeHeight/2)"}
                  },
                  format_mark(opts[:leaves][:rect])
                )
            },
            "from" => %{"data" => "leafNodes"},
            "name" => "leafNode",
            "marks" => [
              %{
                "encode" => %{
                  "update" =>
                    Map.merge(
                      %{
                        "limit" => %{"signal" => "scaledNodeWidth-scaledLimit"},
                        "text" => %{
                          "signal" => "'leaf = ' + format(parent.leaf, '.2f')"
                        },
                        "x" => %{"signal" => "scaledNodeWidth / 2"},
                        "y" => %{"signal" => "scaledNodeHeight / 2"}
                      },
                      format_mark(opts[:leaves][:text])
                    )
                },
                "interactive" => false,
                "name" => "title",
                "type" => "text"
              }
            ],
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
          %{
            "name" => "node",
            "on" => [
              %{
                "events" => %{"markname" => "splitNode", "type" => "click"},
                "update" => "datum.nodeid"
              }
            ],
            "value" => 0
          },
          %{
            "name" => "nodeHighlight",
            "on" => [
              %{
                "events" => [
                  %{"markname" => "splitNode", "type" => "mouseover"},
                  %{"markname" => "leafNode", "type" => "mouseover"}
                ],
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
                "events" => %{"markname" => "splitNode", "type" => "click"},
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
            "update" => "[x_extent[0] - nodeWidth/ 2, x_extent[1] + nodeWidth / 2]"
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
            "update" => "[y_extent[0] - nodeHeight, y_extent[1] + nodeHeight/3]"
          },
          %{"name" => "scaledNodeWidth", "update" => "(nodeWidth/ span(xdom))*width"},
          %{"name" => "scaledNodeHeight", "update" => "abs(nodeHeight/ span(ydom))*height"},
          %{"name" => "scaledLimit", "update" => "(20/ span(xdom))*width"},
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
          }
        ]
      })

    spec = Map.merge(spec, tlk) |> Map.delete("style")
    spec = if opts[:validate], do: validate_spec(spec), else: spec

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

  defp format_mark(opts) do
    opts
    |> opts_to_vl_props()
    |> Enum.into(%{}, fn {key, value} ->
      case key do
        "fontSize" ->
          {"fontSize", %{"signal" => "(#{value}/ span(xdom))*width"}}

        other ->
          {other, %{"value" => value}}
      end
    end)
  end

  defp snake_to_camel(string) do
    [part | parts] = String.split(string, "_")
    Enum.join([String.downcase(part, :ascii) | Enum.map(parts, &capitalize/1)])
  end

  defp capitalize(<<first, rest::binary>>) when first in ?a..?z, do: <<first - 32, rest::binary>>
  defp capitalize(rest), do: rest

  def __after_compile__(env) do
    IO.inspect(env)
  end
end

defimpl Kino.Render, for: EXGBoost.Booster do
  def to_livebook(booster) do
    EXGBoost.Plotting.plot(booster) |> Kino.Render.to_livebook()
  end
end
