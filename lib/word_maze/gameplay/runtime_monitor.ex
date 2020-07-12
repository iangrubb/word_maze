defmodule WordMaze.Gameplay.RuntimeMonitor do

  use GenServer

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.GameRuntime

  def start_link( opts ) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def new_user() do
    GenServer.call(__MODULE__, :new_user)
  end

  def searching(user) do
    WordMazeWeb.Endpoint.subscribe("game:lobby")
    GenServer.call(__MODULE__, {:searching, user})
  end

  def not_searching(user) do
    WordMazeWeb.Endpoint.unsubscribe("game:lobby")
    GenServer.call(__MODULE__, {:not_searching, user})
  end

  def validate_connection(user_id, game_id) do
    GenServer.call(__MODULE__, {:validate_connection, user_id, game_id})
  end

  def find_runtime(game_id) do
    GenServer.call(__MODULE__, {:find_runtime, game_id})
  end





  # Callback Functions

  def init(:ok) do
    {:ok, %{games: %{}, game_id: 1, user_id: 1, waiting_users: []}}
  end

  def handle_call(:new_user, _ , %{user_id: user_id} = state) do
    {:reply, user_id , %{ state | user_id: user_id + 1}}
  end

  def handle_call({:searching, user}, {view_pid, _} , %{waiting_users: waiting_users, games: games, game_id: game_id} = state) do

    monitor_ref = Process.monitor(view_pid)

    new_waiting_users = waiting_users ++ [ Map.merge(user, %{view_pid: view_pid, monitor_ref: monitor_ref}) ]

    case Enum.count(new_waiting_users) >= 2 do
      true ->
        game_users = Enum.map(new_waiting_users, fn u -> %{id: u.id, name: u.name} end)
        new_game = %{id: game_id, players: game_users}

        DynamicSupervisor.start_child(
          WordMaze.GameRuntimeSupervisor,
          {GameRuntime, name: runtime_name(game_id), game_id: game_id, users: game_users}
        )

        WordMazeWeb.Endpoint.broadcast("game:lobby", "game_starting", %{game_id: game_id})
        {:reply, {:game_starting, game_id}, %{ state | waiting_users: [], game_id: game_id + 1, games: Map.put(games, game_id, new_game)}}
      false ->
        WordMazeWeb.Endpoint.broadcast("game:lobby", "list_update", %{waiting: new_waiting_users})
        {:reply, {:waiting, new_waiting_users}, %{ state | waiting_users: new_waiting_users}}
    end
  end

  def handle_call({:not_searching, user}, _, %{waiting_users: waiting_users} = state) do
    case Enum.find_index(waiting_users, fn u -> u.id == user.id end) do
      nil -> {:reply, :ok, state}
      idx -> {:reply, :ok, %{ state | waiting_users: remove_from_list_at_index(waiting_users, idx) }}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{waiting_users: waiting_users} = state) do
    # Handles live view process termination
    case Enum.find_index(waiting_users, fn user -> user.view_pid == pid end) do
      nil -> {:noreply, state}
      idx -> {:noreply, %{ state | waiting_users: remove_from_list_at_index(waiting_users, idx) }}
    end
  end

  def handle_call({:validate_connection, user_id, game_id}, _, %{games: games} = state) do
    game = games[game_id]
    cond do
      game == nil ->
        # REJECT -- Game can't be found.
        {:reply, {:error, "Game number #{game_id} is not available."}, state}
      Enum.any?(game.players, fn player -> player.id == user_id end) ->
        # ACCEPT -- Player has returned.
        {:reply, :ok, state}
      true ->
        # REJECT -- Game is no longer accepting new players.
        {:reply, {:error, "You're not a registered player of game number #{game_id}."}, state}
    end
  end

  def handle_call({:find_runtime, game_id}, _, state) do

  end



  def runtime_name(game_id) do
    {:via, Registry, {WordMaze.GameRegistry, game_id}}
  end

  defp remove_from_list_at_index(list, index) do
    {user, new_list} = List.pop_at(list, index)
    Process.demonitor(user.monitor_ref)
    WordMazeWeb.Endpoint.broadcast("game:lobby", "list_update", %{waiting: new_list})
    new_list
  end

















  def handle_call({:new_connection, pid, player_id, game_id}, _ , {games, views}) do
    # case connect_player_to_game(game_id, player_id) do
    #   :full ->
    #     {:reply, :full, {games, views}}
    #   current_game_state ->
    #     Process.monitor(pid)
    #     new_views = Map.put(views, pid, {player_id, game_id})
    #     new_games =
    #     case Map.has_key?(games, game_id) do
    #       true  -> Map.put(games, game_id, [ player_id | games[game_id] ])
    #       false -> Map.put(games, game_id, [ player_id ])
    #     end
    #   {:reply, current_game_state, {new_games, new_views}}
    # end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, {games, views}) do

    {{player_id, game_id}, new_views} = Map.pop(views, pid)
    { player_list , remaining_games } = Map.pop(games, game_id)
    new_players = Enum.reject(player_list, fn p -> p == player_id end)
    new_games = Map.put(remaining_games, game_id,  new_players)

    if new_players == [] do
      my_pid = self()
      spawn(fn ->
        :timer.sleep(5000)
        send(my_pid, {:consider_shutdown, game_id})
      end)
    end

    {:noreply, {new_games, new_views}}
  end

  def handle_info({:consider_shutdown, game_id}, {games, views}) do
    case games[game_id] do
      [] ->
        DynamicSupervisor.terminate_child(WordMaze.GameRuntimeSupervisor, runtime_name(game_id) )
        { _ , new_games} = Map.pop(games, game_id)
        {:noreply, {new_games, views}}
      _  -> {:noreply, {games, views}}
    end
  end




end
