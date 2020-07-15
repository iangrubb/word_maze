defmodule WordMazeWeb.UserController do
  use WordMazeWeb, :controller

  alias WordMaze.Gameplay.RuntimeMonitor

  def new(conn, _params) do

    IO.puts get_session(conn, :user).beef

    case RuntimeMonitor.valid_session?(get_session(conn, :user)) do
      false -> render(conn, "new.html")
      true -> redirect(conn, to: Routes.game_path(conn, :index))
    end
  end

  def create(conn, %{"user" => %{"name" => name}}) do
    {user_id, session_key} = RuntimeMonitor.new_user()
    conn
    |> put_session(:user, %{id: user_id, name: name, session_key: session_key})
    |> redirect(to: Routes.game_path(conn, :index))
  end

end
