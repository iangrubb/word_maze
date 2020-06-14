defmodule WordMaze.Gameplay.GameRuntime do

  alias WordMaze.Gameplay.{ Visibility, GameInitializer, Players }

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
    {:ok, GameInitializer.new_game_state(game_id)}
  end

  def handle_call(:get_pid, _from, state) do
    {:reply, self(), state}
  end

  def handle_call({:attempt_player_join, player_id}, _from, state) do
      cond do
        Enum.count(state.players, fn {id, _} -> id == player_id  end) > 0 ->
          # Old player is rejoining
          player_state = Players.get_state(state, player_id)
          IO.puts "OLD RETURNS"
          {:reply, player_state, state}
        Enum.count(state.players) < 4 ->
          # New player has space to be added
          new_state = Players.initialize(state, player_id)
          player_state = Players.get_state(new_state, player_id)
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


  # Socket Messages

  def handle_info(%{event: "server:" <> _message }, state) do
    {:noreply, state}
  end

  def handle_info(%{event: "client:move", payload: %{player_id: player_id, direction: direction}} = message, state) do
    updated_state = attempt_move(state, player_id, direction)
    {:noreply, updated_state}
  end

  defp attempt_move(state, player_id, direction) do

    {x, y} = state.players[player_id].location

    target =
      case direction do
        :left   -> {x - 1, y}
        :down   -> {x, y + 1}
        :up     -> {x, y - 1}
        :right  -> {x + 1, y}
      end

    case state.spaces[target].open do
      true ->

        player = state.players[player_id]

        viewing_spaces = Visibility.visible_spaces(state.spaces, target)
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





end
