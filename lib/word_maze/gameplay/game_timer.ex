defmodule WordMaze.Gameplay.GameTimer do
  use GenServer

  def start_link(parent, duration) do
    GenServer.start_link(__MODULE__, {parent, duration, true})
  end

  def pause(pid) do
    GenServer.cast(pid, :pause)
  end

  def init(state) do
    :timer.send_interval(1000, :tick)
    {:ok, state}
  end

  def handle_info(:tick, {parent, duration, running}) do

    case {duration, running} do
      {_ , false} ->
        {:noreply, {parent, duration, running}}
      {0, true} ->
        send(parent, {:timer_tick, duration})
        {:noreply, {parent, duration - 1, false}}
      {_ ,true} ->
        send(parent, {:timer_tick, duration})
        {:noreply, {parent, duration - 1, running}}

    end

  end

  def handle_info(:pause, {parent, duration, _}) do
    {:noreply, {parent, duration, false}}
  end

end
