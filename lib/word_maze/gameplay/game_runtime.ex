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
    GenServer.start_link(__MODULE__, opts[:game_id] , opts)
  end

  # Runtime API

  def attempt_player_join(pid, player_id) do
    GenServer.call(pid, {:attempt_player_join, player_id})
  end

  def get_pid(pid) do
    GenServer.call(pid, :get_pid)
  end




  # Runtime Callbacks

  def init(game_id) do
    WordMazeWeb.Endpoint.subscribe("game:client:#{game_id}")
    {:ok, new_game_state()}
  end

  def handle_call(:get_pid, _from, state) do
    {:reply, self(), state}
  end

  def handle_call({:attempt_player_join, player_id}, _from, state) do

      cond do
        Enum.count(state.players, fn {_key, val} -> val.id == player_id  end) > 0 ->
          # Old player is rejoining
          IO.puts "OLD RETURNS"
          IO.puts player_id
          IO.inspect state.players
          {:reply, state, state}
        Enum.count(state.players) < 4 ->
          # New player has space to be added
          IO.puts "NEW JOINS"
          new_state = %{state | players: Map.put(state.players, Enum.count(state.players) + 1, %{id: player_id})}
          IO.inspect new_state.players
          {:reply, new_state, new_state}
        true ->
          # New player has no space and can't join
          IO.puts "New Denied"
          IO.inspect state.players
          {:reply, :full, state}
      end

  end

  def handle_info(%{event: "departure", payload: %{player_id: player_id}}, state) do

    {_removed, new_players} = Map.pop(state.players, player_id)

    {:noreply, %{ state | players: new_players }}
  end





  # Gameplay Logic

  def new_game_state() do

    defaults = %{
      players: %{},
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
