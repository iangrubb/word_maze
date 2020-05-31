defmodule WordMazeWeb.GameLive.Monitor do

  use GenServer

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.GameRuntime

  def start_link( opts ) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def new_connection(pid, player_id, game_id) do
    GenServer.call(__MODULE__, {:new_connection, pid, player_id, game_id})
  end

  def init(:ok) do
    {:ok, {%{}, %{}}}
  end

  def handle_call({:new_connection, pid, player_id, game_id}, _ , {games, views}) do

    current_game_state = connect_player_to_game(game_id, player_id)
    Process.monitor(pid)
    # add case check later for exceeding player count limit

    new_views = Map.put(views, pid, {player_id, game_id})

    new_games =
      case Map.has_key?(games, game_id) do
        true  -> Map.put(games, game_id, [ player_id | games[game_id] ])
        false -> Map.put(games, game_id, [ player_id ])
      end

    {:reply, current_game_state, {new_games, new_views}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, {games, views}) do

    {{player_id, game_id}, new_views} = Map.pop(views, pid)

    { player_list , remaining_games } = Map.pop(games, game_id)
    new_players = Enum.reject(player_list, fn p -> p == player_id end)
    new_games = Map.put(remaining_games, game_id,  new_players)

    if new_players == [] do

      my_pid = self()
      spawn(fn ->
        :timer.sleep(5000);
        send(my_pid, {:consider_shutdown, game_id})
      end)

    end

    {:noreply, {new_games, new_views}}
  end

  def handle_info({:consider_shutdown, game_id}, {games, views}) do

    case games[game_id] do
      [] ->
        DynamicSupervisor.terminate_child(WordMaze.GameRuntimeSupervisor, find_pid(game_id) )
        { _ , new_games} = Map.pop(games, game_id)
        {:noreply, {new_games, views}}
      _  -> {:noreply, {games, views}}
    end

  end

  defp connect_player_to_game(game_id, user_id) do

    DynamicSupervisor.start_child(WordMaze.GameRuntimeSupervisor, {GameRuntime, name: find_runtime(game_id), player_id: user_id, game_id: game_id})
    GameRuntime.get_current_state(find_runtime(game_id), user_id)

  end

  defp find_runtime(game_id) do
    {:via, Registry, {WordMaze.GameRegistry, game_id}}
  end

  defp find_pid(game_id) do
    GameRuntime.get_pid(find_runtime(game_id))
  end


end
