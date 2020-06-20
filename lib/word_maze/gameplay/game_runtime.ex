defmodule WordMaze.Gameplay.GameRuntime do

  alias WordMaze.Gameplay.{ Visibility, GameInitializer, Players, Movement, Words }

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

  def handle_info(%{event: "client:move", payload: %{player_id: player_id, direction: direction}}, state) do
    players = Movement.attempt_move(state.spaces, state.players, state.game_id, player_id, direction)
    {:noreply, %{ state | players: players }}
  end

  def handle_info( %{event: "client:submit_words", payload: %{player_id: player_id, submissions: submissions}}, state ) do

    case Words.validate_submissions(submissions, state.spaces) do
      true ->

        updates = Enum.map(submissions, fn submission -> Words.add_submission(submission, state.spaces) end)

        updates =
          case updates do
            [ updates ]             -> updates
            [ updates1, updates2 ]  -> Map.merge(updates1, updates2)
          end

        new_spaces = Enum.reduce( state.spaces, %{}, fn ({ loc , space }, acc) ->
          case Map.fetch(updates, loc) do
            :error -> Map.put(acc, loc, space)
            {:ok, letter} -> Map.put(acc, loc, %{ space | letter: letter })
          end
        end)

        combined_submissions =
          case submissions do
            [ sub ]             -> sub
            [ sub1, sub2 ]  -> Map.merge(sub1, sub2)
          end

        letters_used =
          combined_submissions
          |> Enum.filter(fn {_ , _ , idx} -> idx != nil end)

        player = state.players[player_id]

        updated_player =
          player
          |> Map.put(:letters, player.letters -- Enum.map(letters_used, fn {l , _ , _} -> l end))

        WordMazeWeb.Endpoint.broadcast(
          "game:#{state.game_id}", "server:submission_success",
          %{player_id: player_id, new_spaces: new_spaces, letters_used: letters_used}
        )

        {:noreply, %{ state | spaces: new_spaces, players: Map.put(state.players, player_id, updated_player)}}
      false ->
        {:noreply, state}
    end

  end




end
