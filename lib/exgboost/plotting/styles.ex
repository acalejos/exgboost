defmodule EXGBoost.Plotting.Styles do
  @moduledoc """
  A style is a keyword-map that adheres to the plotting schema
  as defined in `EXGBoost.Plotting`.
  """

  def solarized_light(),
    do: [
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

  def solarized_dark(),
    do: [
      # base03
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

  def playful_light(),
    do: [
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

  def playful_dark(),
    do: [
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

  def dark(),
    do: [
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

  def high_contrast(),
    do: [
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

  def light(),
    do: [
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

  def monokai(),
    do: [
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

  def dracula(),
    do: [
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

  def nord(),
    do: [
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

  def material(),
    do: [
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

  def one_dark(),
    do: [
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

  def gruvbox(),
    do: [
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
