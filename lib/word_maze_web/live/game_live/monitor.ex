defmodule WordMazeWeb.GameLive.Monitor do

  use GenServer

  def start_link( opts ) do
    GenServer.start_link(__MODULE__, :ok)
  end

  # Api

  def monitor(pid, player_id) do
    GenServer.call(__MODULE__, {:monitor, pid, player_id})
  end


  # Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:monitor, pid, player_id}, _ , views) do
    Process.monitor(pid)
    {:reply, :ok, Map.put(views, pid, player_id)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, views) do

    {player_id, new_views} = Map.pop(views, pid)

    WordMazeWeb.GameLive.Show.unmount(player_id)

    {:noreply, new_views}
  end



end
