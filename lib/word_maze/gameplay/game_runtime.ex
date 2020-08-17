defmodule WordMaze.Gameplay.GameRuntime do

  alias WordMaze.Gameplay.{ RuntimeMonitor, Visibility, GameInitializer, Players, Movement, Words, Letters, GameTimer }

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts , opts)
  end

  # Runtime API

  ## Game Setup Utilities

  def get_player_state(pid, player_id) do
    GenServer.call(pid, {:get_player_state, player_id})
  end




  def get_pid(pid) do
    GenServer.call(pid, :get_pid)
  end

  # Runtime Callbacks

  def init(opts) do
    game_id = opts[:game_id]
    WordMazeWeb.Endpoint.subscribe("game:#{game_id}")
    duration = 10
    GameTimer.start_link(self(), 245)
    {:ok, GameInitializer.new_game_state(game_id, opts[:users])}
  end

  def handle_call(:get_pid, _from, state) do
    {:reply, self(), state}
  end



  # Write ways to set and get player state in runtime


  def handle_call({:get_player_state, player_id}, _ , state) do
    {:reply, Players.get_state(state, player_id), state}
  end





  def handle_info({:new_letter, player_id, letters_after}, state) do

    %{players: players, game_id: game_id} = state

    if letters_after > 0 do
      new_players = Letters.give_letter(players, player_id, game_id)
      Letters.schedule_new_letter(player_id, 1000, letters_after - 1)
      {:noreply, %{ state | players: new_players}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:timer_tick, duration} , state) do
    case duration do
      240 ->
        WordMazeWeb.Endpoint.broadcast(
        "game:#{state.game_id}", "server:game_start",
        %{duration: duration}
        )
        {:noreply, %{state | duration: duration, status: :running}}
      0 ->
        WordMazeWeb.Endpoint.broadcast(
        "game:#{state.game_id}", "server:game_complete",
        %{}
        )
        RuntimeMonitor.end_game(state.game_id)
        {:noreply, %{state | duration: duration, status: :complete}}
      _ ->
        WordMazeWeb.Endpoint.broadcast(
        "game:#{state.game_id}", "server:timer_update",
        %{duration: duration}
        )
        {:noreply, %{state | duration: duration}}
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

        Letters.schedule_new_letter(player_id, 1000, Enum.count(letters_used))

        player = state.players[player_id]
        words =
          submissions
          |> Enum.map(fn sub -> Words.extract_word_from_submission(sub) end)
          |> Enum.join(" and ")
        message = "#{String.capitalize(player.name)} has played #{words} for #{added_score} points"

        game_status = if updated_player.score >= 150, do: :complete, else: :running

        WordMazeWeb.Endpoint.broadcast(
          "game:#{state.game_id}", "server:submission_success",
          %{player_id: player_id, new_spaces: new_spaces, letters_used: letters_used, new_score: updated_player.score, message: message, game_status: game_status}
        )

        {:noreply, %{ state | spaces: new_spaces, players: Map.put(state.players, player_id, updated_player), status: game_status}}
      false ->

        WordMazeWeb.Endpoint.broadcast(
          "game:#{state.game_id}", "server:submission_failure",
          %{player_id: player_id}
        )

        {:noreply, state}
    end
  end

  def handle_info(%{event: "client:discard", payload: %{player_id: player_id, letter: letter}}, state) do

    player = state.players[player_id]

    updated_player = Map.put(player, :letters, List.delete(player.letters, letter))

    Letters.schedule_new_letter(player_id, 3000, 1)

    {:noreply, %{ state | players: Map.put(state.players, player_id, updated_player)}}
  end




end
