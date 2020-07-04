defmodule WordMaze.Gameplay.GameInitializer do

  def new_game_state(game_id, duration) do

    defaults = %{
      game_id: game_id,
      duration: duration,
      players: %{},
      status: :running
    }

    defaults
    |> build_board()

  end

  @alphabet ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

  @board [
    ~w(╔ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ╗),
    ~w(║ n . . . █ 2 . e . . █ . . e . 2 █ . . . n ║),
    ~w(║ . █ █ . a . █ █ █ . █ . █ █ █ . a . █ █ . ║),
    ~w(║ . . 2 . █ . █ █ 3 . . . 3 █ █ . █ . 2 . . ║),
    ~w(║ █ █ . █ █ . . . . █ . █ . . . . █ █ . █ █ ║),
    ~w(║ █ t . . █ █ █ . █ █ . █ █ . █ █ █ . . t █ ║),
    ~w(║ █ . █ . . . . . █ . 4 . █ . . . . . █ . █ ║),
    ~w(║ █ . . 3 █ . █ . . . █ . . . █ . █ 3 . . █ ║),
    ~w(║ █ . █ █ █ 3 █ █ █ . █ . █ █ █ 3 █ █ █ . █ ║),
    ~w(║ . . . █ . . . █ 3 . . . 3 █ . . . █ . . . ║),
    ~w(║ . █ . █ . █ . . . █ . █ . . . █ . █ . █ . ║),
    ~w(║ s . 2 . . █ 4 █ . . 5 . . █ 4 █ . . 2 . s ║),
    ~w(║ . █ . █ . █ . . . █ . █ . . . █ . █ . █ . ║),
    ~w(║ . . . █ . . . █ 3 . . . 3 █ . . . █ . . . ║),
    ~w(║ █ . █ █ █ 3 █ █ █ . █ . █ █ █ 3 █ █ █ . █ ║),
    ~w(║ █ . . 3 █ . █ . . . █ . . . █ . █ 3 . . █ ║),
    ~w(║ █ . █ . . . . . █ . 4 . █ . . . . . █ . █ ║),
    ~w(║ █ t . . █ █ █ . █ █ . █ █ . █ █ █ . . t █ ║),
    ~w(║ █ █ . █ █ . . . . █ . █ . . . . █ █ . █ █ ║),
    ~w(║ . . 2 . █ . █ █ 3 . . . 3 █ █ . █ . 2 . . ║),
    ~w(║ . █ █ . a . █ █ █ . █ . █ █ █ . a . █ █ . ║),
    ~w(║ n . . . █ 2 . e . . █ . . e . 2 █ . . . n ║),
    ~w(╚ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ╝)
  ]

  def build_board(state) do

    {_, all_spaces} =
      Enum.reduce(@board, {0, %{}}, fn row, {y_idx, acc} ->
        # Iterate over the board rows, put the maps for the cells of each into a single map
        {_, row_spaces} =
          Enum.reduce(row, {0, acc}, fn
            # Iterate over the board cells, put them in a map for the row
            "╔", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, border_tl(x_idx, y_idx))}
            "═", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, border_h(x_idx, y_idx))}
            "╗", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, border_tr(x_idx, y_idx))}
            "║", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, border_v(x_idx, y_idx))}
            "╝", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, border_br(x_idx, y_idx))}
            "╚", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, border_bl(x_idx, y_idx))}
            "█", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, wall(x_idx, y_idx))}
            ".", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, path(x_idx, y_idx))}
            value, {x_idx, acc} ->
              case Enum.member?(@alphabet, value) do
                true  -> {x_idx + 1, Map.put(acc, {x_idx, y_idx}, letter_path(x_idx, y_idx, value))}
                false ->
                  { number, _ } = Integer.parse(value)
                  {x_idx + 1, Map.put(acc, {x_idx, y_idx}, number_path(x_idx, y_idx, number))}
              end
          end)
        {y_idx + 1, row_spaces}
      end)

    Map.put(state, :spaces, all_spaces)
  end

  defp border_tl(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_tl", multiplier: 1}
  end

  defp border_h(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_h", multiplier: 1}
  end

  defp border_tr(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_tr", multiplier: 1}
  end

  defp border_v(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_v", multiplier: 1}
  end

  defp border_br(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_br", multiplier: 1}
  end

  defp border_bl(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_bl", multiplier: 1}
  end

  defp path(x, y) do
    %{open: true, letter: nil, x: x, y: y, class: "path", multiplier: 1}
  end

  defp letter_path(x, y, letter) do
    %{open: true, letter: letter, x: x, y: y, class: "path", multiplier: 1}
  end

  defp wall(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "wall", multiplier: 1}
  end

  defp number_path(x, y, number) do
    %{open: true, letter: nil, x: x, y: y, class: "path", multiplier: number}
  end

end
