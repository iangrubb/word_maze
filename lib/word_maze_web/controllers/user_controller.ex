defmodule WordMazeWeb.UserController do
  use WordMazeWeb, :controller

  alias WordMaze.Gameplay.RuntimeMonitor

  def new(conn, _params) do
    case get_session(conn, :user) do
      nil -> render(conn, "new.html")
      _ -> redirect(conn, to: Routes.game_path(conn, :index))
    end
  end

  def create(conn, %{"user" => %{"name" => name}}) do
    user_id = RuntimeMonitor.new_user()
    conn
    |> put_session(:user, %{id: user_id, name: name})
    |> redirect(to: Routes.game_path(conn, :index))
  end

end
