defmodule WordMaze.Gameplay.GameRuntime do

  alias WordMaze.Gameplay.GameHelpers

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:game_id] , opts)
  end

  # Runtime API

  ## Game Setup Utilities

  def attempt_player_join(pid, player_id) do
    GenServer.call(pid, {:attempt_player_join, player_id})
  end

  def get_pid(pid) do
    GenServer.call(pid, :get_pid)
  end


  # Runtime Callbacks

  def init(game_id) do
    WordMazeWeb.Endpoint.subscribe("game:#{game_id}")
    IO.puts "Starting #{game_id}"
    {:ok, initialize_game_state(game_id)}
  end

  def handle_call(:get_pid, _from, state) do
    {:reply, self(), state}
  end

  def handle_call({:attempt_player_join, player_id}, _from, state) do
      cond do
        Enum.count(state.players, fn {id, _} -> id == player_id  end) > 0 ->
          # Old player is rejoining
          player_state = extract_state_for_player(state, player_id)
          IO.puts "OLD RETURNS"
          {:reply, player_state, state}
        Enum.count(state.players) < 4 ->
          # New player has space to be added
          new_state = initialize_player_state(state, player_id)
          player_state = extract_state_for_player(new_state, player_id)
          new_player_data = player_state.players[player_id]
          IO.puts "NEW JOINS"
          WordMazeWeb.Endpoint.broadcast("game:#{state.game_id}", "server:new_player", %{player: new_player_data, player_id: player_id})
          {:reply, player_state, new_state}
        true ->
          # New player has no space and can't join
          IO.puts "New Denied"
          {:reply, :full, state}
      end
  end





  # Gameplay Logic

  # Game initialization on start

  def initialize_game_state(game_id) do

    defaults = %{
      game_id: game_id,
      players: %{},
    }

    defaults
    |> build_board()

  end

  def extract_state_for_player(state, player_id) do

    player_data = state.players[player_id]

    %{
      spaces: state.spaces,
      hand: player_data.hand,
      viewed_spaces: player_data.viewed_spaces,
      viewed_letters: player_data.viewed_letters,
      players: Enum.reduce(state.players, %{}, fn ({player_id, data}, acc) -> Map.put(acc, player_id, %{ score: data.score, color: data.color, location: data.location}) end )
    }
  end


  @board [
    ~w(╔ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ╗),
    ~w(║ s . . . █ . . . . . █ . . . . . █ . . . s ║),
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
    ~w(║ s . . . █ . . . . . █ . . . . . █ . . . s ║),
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
            letter, {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {x_idx, y_idx}, letter_path(x_idx, y_idx, letter))}
          end)
        {y_idx + 1, row_spaces}
      end)

    Map.put(state, :spaces, all_spaces)
  end

  defp border_tl(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_tl"}
  end

  defp border_h(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_h"}
  end

  defp border_tr(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_tr"}
  end

  defp border_v(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_v"}
  end

  defp border_br(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_br"}
  end

  defp border_bl(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "border_bl"}
  end

  defp path(x, y) do
    %{open: true, letter: nil, x: x, y: y, class: "path"}
  end

  defp letter_path(x, y, letter) do
    %{open: true, letter: letter, x: x, y: y, class: "path"}
  end

  defp wall(x, y) do
    %{open: false, letter: nil, x: x, y: y, class: "wall"}
  end




  # Player state initialization on first join

  def initialize_player_state(state, player_id) do

    generate_letter()

    defaults = %{
      score: 0,
    }

    player_state =
      defaults
      |> set_initial_location(Enum.count(state.players))
      |> set_color(Enum.count(state.players))
      |> set_initial_hand()
      |> set_initial_view(state.spaces)

    %{state | players: Map.put(state.players, player_id, player_state)}
  end

  def set_initial_location(player_state, player_count) do

    location =
      case player_count do
        0 -> {1, 1}
        1 -> {21, 21}
        2 -> {21, 1}
        3 -> {1, 21}
      end
    Map.put(player_state, :location, location)
  end

  def set_color(player_state, player_count) do

    color =
      case player_count do
        0 -> "red"
        1 -> "blue"
        2 -> "green"
        3 -> "yellow"
      end
    Map.put(player_state, :color, color)

  end

  def set_initial_hand(player_state) do
    hand =
      [1, 2, 3, 4, 5, 6]
      |> Enum.map(fn _n -> generate_letter() end )
    Map.put(player_state, :hand, hand)
  end

  def set_initial_view(player_state, spaces) do

    # Finish this by calculating views

    viewed_spaces = GameHelpers.visible_spaces(spaces, player_state.location)
    viewed_letters = Enum.filter(viewed_spaces, fn address -> spaces[address].letter !== nil end)

    player_state
    |> Map.put(:viewed_spaces, viewed_spaces)
    |> Map.put(:viewed_letters, viewed_letters)

  end






  def handle_info(%{event: "server:" <> _message }, state) do
    {:noreply, state}
  end


  # Movement Logic

  def handle_info(%{event: "client:move", payload: %{player_id: player_id, direction: direction}} = message, state) do
    updated_state = attempt_move(state, player_id, direction)
    {:noreply, updated_state}
  end

  defp attempt_move(state, player_id, direction) do

    {x, y} = state.players[player_id].location

    target =
      case direction do
        "ArrowLeft" -> {x - 1, y}
        "ArrowDown" -> {x, y + 1}
        "ArrowUp" -> {x, y - 1}
        "ArrowRight" -> {x + 1, y}
      end

    case state.spaces[target].open do
      true ->

        player = state.players[player_id]

        viewing_spaces = GameHelpers.visible_spaces(state.spaces, target)
        viewed_spaces =
          player.viewed_spaces
          |> Enum.concat(viewing_spaces)
          |> Enum.uniq()

        viewing_letters = Enum.filter(viewing_spaces, fn address -> state.spaces[address].letter !== nil end)
        viewed_letters =
          player.viewed_letters
          |> Enum.concat(viewing_letters)
          |> Enum.uniq()

        WordMazeWeb.Endpoint.broadcast("game:#{state.game_id}", "server:new_location",
          %{
            player_id: player_id,
            location: target,
            viewing_spaces: viewing_spaces,
            viewing_letters: viewing_letters
          }
        )

        new_player = %{ player | location: target, viewed_spaces: viewed_spaces, viewed_letters: viewed_letters }

        %{state | players: Map.put(state.players, player_id, new_player)}
      false -> state
    end
  end


  # Hand Logic

  def current_letters(spaces, players) do

    hand_letters = Enum.flat_map(players, fn player -> player.hand end)
    board_letters =
      spaces
      |> Enum.filter(fn space -> space.letter != nil end)
      |> Enum.map(fn space -> space.letter end)

    Enum.concat(hand_letters, board_letters)
    |> Enum.reduce(%{}, fn (letter, acc) ->
        case Map.has_key?(acc, letter) do
          true -> Map.put(acc, letter, acc[letter] + 1)
          false -> Map.put(acc, letter, 1)
        end
      end)
  end

  def generate_letter() do

    total =
      GameHelpers.letter_frequencies()
      |> Enum.reduce(0, fn ({_letter, count}, acc) -> acc + count end)

    value = :rand.uniform(total)

    {_acc, letter} =
      GameHelpers.letter_frequencies()
      |> Enum.reduce( {0, nil} , fn ({letter, count}, {acc, target}) ->
        cond do
          target != nil         -> {acc, target}
          acc + count >= value  -> {acc, letter}
          true                  -> {acc + count, nil}
        end
      end)

    letter
  end





end
