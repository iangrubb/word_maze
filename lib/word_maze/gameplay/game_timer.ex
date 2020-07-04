defmodule WordMaze.Gameplay.GameTimer do
  use GenServer

  def start_link(parent, duration) do
    GenServer.start_link(__MODULE__, {parent, duration})
  end


  def init(state) do
    :timer.send_interval(1000, :tick)
    {:ok, state}
  end

  def handle_info(:tick, {parent, duration}) do
    send(parent, {:timer_tick, duration})
    {:noreply, {parent, duration - 1}}
  end

end
