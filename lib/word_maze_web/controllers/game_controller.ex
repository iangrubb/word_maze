defmodule WordMazeWeb.GameController do
  use WordMazeWeb, :controller

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.Game

  def index(conn, _params) do
    games = Gameplay.list_games_with_players()
    render(conn, "index.html", games: games)
  end

  # def new(conn, _params) do
  #   changeset = Gameplay.change_game(%Game{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def create(conn, %{"game" => game_params}) do
  #   case Gameplay.create_game(game_params) do
  #     {:ok, game} ->
  #       conn
  #       |> put_flash(:info, "Game created successfully.")
  #       |> redirect(to: Routes.game_path(conn, :show, game))

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end

  def show(conn, %{"id" => id}) do
    game = Gameplay.get_game!(id)
    player_id = :rand.uniform(10000)
    render(conn, "show.html", game: game, player_id: player_id)
  end

  # def edit(conn, %{"id" => id}) do
  #   game = Gameplay.get_game!(id)
  #   changeset = Gameplay.change_game(game)
  #   render(conn, "edit.html", game: game, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "game" => game_params}) do
  #   game = Gameplay.get_game!(id)

  #   case Gameplay.update_game(game, game_params) do
  #     {:ok, game} ->
  #       conn
  #       |> put_flash(:info, "Game updated successfully.")
  #       |> redirect(to: Routes.game_path(conn, :show, game))

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "edit.html", game: game, changeset: changeset)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   game = Gameplay.get_game!(id)
  #   {:ok, _game} = Gameplay.delete_game(game)

  #   conn
  #   |> put_flash(:info, "Game deleted successfully.")
  #   |> redirect(to: Routes.game_path(conn, :index))
  # end
end
