defmodule WordMazeWeb.GameController do
  use WordMazeWeb, :controller
  import Phoenix.LiveView.Controller

  alias WordMaze.Gameplay.RuntimeMonitor

  def index(conn, _params) do
    case get_session(conn, :user) do
      nil -> redirect(conn, to: Routes.user_path(conn, :new))
      user ->live_render(conn, WordMazeWeb.GameLive.Lobby)
    end
  end

  def show(conn, %{"id" => game_id}) do

    game_id = String.to_integer(game_id)

    case get_session(conn, :user) do
      nil ->
        redirect(conn, to: Routes.user_path(conn, :new))
      user ->
        case RuntimeMonitor.validate_connection(user.id, game_id) do
          :ok ->
            live_render(conn, WordMazeWeb.GameLive.Game, session: %{"game_id" => game_id, "player_id" => user.id})
          {:error, reason} ->
            redirect(conn, to: Routes.game_path(conn, :index))
        end
    end
  end


end
