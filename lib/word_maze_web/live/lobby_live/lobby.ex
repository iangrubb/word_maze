defmodule WordMazeWeb.GameLive.Lobby do
  use WordMazeWeb, :live_view

  def mount(_params, _session, socket) do
      {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="ui-box">Lobby</div>
    """
  end


end
