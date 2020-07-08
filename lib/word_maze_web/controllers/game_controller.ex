defmodule WordMazeWeb.GameController do
  use WordMazeWeb, :controller
  import Phoenix.LiveView.Controller

  def landing(conn, _params) do
    render(conn, "landing.html")
  end

  def index(conn, _params) do

    live_render(conn, WordMazeWeb.GameLive.Lobby)

  end

  def show(conn, %{"id" => game_id}) do

    # Way to communicate player info between live views:
    # Conn.get_session(conn, :player_id)

    player_id = :rand.uniform(10000)
    live_render(conn, WordMazeWeb.GameLive.Game, session: %{"game_id" => game_id, "player_id" => player_id})

  end

end
