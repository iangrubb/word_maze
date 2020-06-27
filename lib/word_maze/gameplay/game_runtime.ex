defmodule WordMaze.Gameplay.GameRuntime do

  alias WordMaze.Gameplay.{ Visibility, GameInitializer, Players, Movement, Words, Letters }

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

  def handle_info({:new_letter, player_id}, state) do

    %{players: players, game_id: game_id} = state

    if Enum.count(players[player_id].letters) < 7 do
      new_players = Letters.give_letter(players, player_id, game_id)
      Letters.schedule_new_letter(player_id)
      {:noreply, %{ state | players: new_players}}
    else
      {:noreply, state}
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

  def handle_info(%{event: "client:submit_words", payload: %{player_id: player_id, submissions: submissions}}, state ) do
    case Words.validate_submissions(submissions, state.spaces) do
      true ->

        new_spaces = Words.update_spaces_for_submissions(submissions, state.spaces)
        letters_used = Words.letters_used_by_submissions(submissions)
        added_score = Words.submissions_score(submissions, state.spaces)
        updated_player = Words.player_after_submission( state.players[player_id], letters_used, added_score )

        Letters.schedule_new_letter(player_id)

        WordMazeWeb.Endpoint.broadcast(
          "game:#{state.game_id}", "server:submission_success",
          %{player_id: player_id, new_spaces: new_spaces, letters_used: letters_used, new_score: updated_player.score}
        )

        {:noreply, %{ state | spaces: new_spaces, players: Map.put(state.players, player_id, updated_player)}}
      false ->

        WordMazeWeb.Endpoint.broadcast(
          "game:#{state.game_id}", "server:submission_failure",
          %{player_id: player_id}
        )

        {:noreply, state}
    end
  end




end
