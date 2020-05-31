defmodule WordMaze.Gameplay.GameRuntime do

  use GenServer

  @board [
    ~w(╔ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ╗),
    ~w(║ . . . . █ . . . . . █ . . . . . █ . . . . ║),
    ~w(║ . █ █ . . . █ █ █ . █ . █ █ █ . . . █ █ . ║),
    ~w(║ . . . . █ . █ █ . . . . . █ █ . █ . . . . ║),
    ~w(║ █ █ . █ █ . . . . █ . █ . . . . █ █ . █ █ ║),
    ~w(║ █ . . . █ █ █ . █ █ . █ █ . █ █ █ . . . █ ║),
    ~w(║ █ . █ . . . . . █ . . . █ . . . . . █ . █ ║),
    ~w(║ █ . . . █ . █ . . . █ . . . █ . █ . . . █ ║),
    ~w(║ █ . █ █ █ . █ █ █ . █ . █ █ █ . █ █ █ . █ ║),
    ~w(║ . . . █ . . . █ . . . . . █ . . . █ . . . ║),
    ~w(║ . █ . █ . █ . . . █ . █ . . . █ . █ . █ . ║),
    ~w(║ . . . . . █ . █ . . . . . █ . █ . . . . . ║),
    ~w(║ . █ . █ . █ . . . █ . █ . . . █ . █ . █ . ║),
    ~w(║ . . . █ . . . █ . . . . . █ . . . █ . . . ║),
    ~w(║ █ . █ █ █ . █ █ █ . █ . █ █ █ . █ █ █ . █ ║),
    ~w(║ █ . . . █ . █ . . . █ . . . █ . █ . . . █ ║),
    ~w(║ █ . █ . . . . . █ . . . █ . . . . . █ . █ ║),
    ~w(║ █ . . . █ █ █ . █ █ . █ █ . █ █ █ . . . █ ║),
    ~w(║ █ █ . █ █ . . . . █ . █ . . . . █ █ . █ █ ║),
    ~w(║ . . . . █ . █ █ . . . . . █ █ . █ . . . . ║),
    ~w(║ . █ █ . . . █ █ █ . █ . █ █ █ . . . █ █ . ║),
    ~w(║ . . . . █ . . . . . █ . . . . . █ . . . . ║),
    ~w(╚ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ╝)
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:player_id], opts)
  end

  # Runtime API

  def live_state(pid) do
    GenServer.call(pid, :live_state)
  end





  # Runtime Callbacks

  def init(player_id) do
    {:ok, new_game_state(player_id)}
  end

  def handle_call(:live_state, _from, state) do
    {:reply, state, state}
  end









  # Gameplay Logic

  def new_game_state(player_id) do

    defaults = %{
      players: [player_id],
      player_x: 1,
      player_y: 1,
      blocks: %{}
    }

    defaults
    |> build_board()

  end

  def build_board(state) do

    {_, all_blocks} =
      Enum.reduce(@board, {0, %{}}, fn row, {y_idx, acc} ->
        # Iterate over the board rows, put the maps for the cells of each into a single map
        {_, row_blocks} =
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
          end)
        {y_idx + 1, row_blocks}
      end)

    %{ state | blocks: all_blocks }

  end

  defp border_tl(x, y) do
    %{passable: false, x: x, y: y, class: "border_tl"}
  end

  defp border_h(x, y) do
    %{passable: false, x: x, y: y, class: "border_h"}
  end

  defp border_tr(x, y) do
    %{passable: false, x: x, y: y, class: "border_tr"}
  end

  defp border_v(x, y) do
    %{passable: false, x: x, y: y, class: "border_v"}
  end

  defp border_br(x, y) do
    %{passable: false, x: x, y: y, class: "border_br"}
  end

  defp border_bl(x, y) do
    %{passable: false, x: x, y: y, class: "border_bl"}
  end

  defp path(x, y) do
    %{passable: true, x: x, y: y, class: "path"}
  end

  defp wall(x, y) do
    %{passable: false, x: x, y: y, class: "wall"}
  end



end
