defmodule WordMaze.Gameplay do
  @moduledoc """
  The Gameplay context.
  """

  import Ecto.Query, warn: false
  alias WordMaze.Repo

  alias WordMaze.Gameplay.{ Game, GameUser, GameRuntime}

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  def list_games_with_players do
    query = from g in Game, preload: :players
    Repo.all(query)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)



  def create_game_by_user(user) do

    {:ok, game} = result =
      %Game{}
      |> Game.changeset(%{status: "initializing"})
      |> Repo.insert()

    add_user_to_game(user, game)

    result
  end

  def add_user_to_game(user, game) do
    game = Repo.preload(game, [:players])

    game
    |> Game.changeset_players([user | game.players])
    |> Repo.update()
  end



  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end





  def connect_player_to_game(game_id, user_id) do

    # In cases of successful connection, something should be recorded in database.

    case DynamicSupervisor.start_child(WordMaze.GameRuntimeSupervisor, {GameRuntime, name: find_runtime(game_id), player_id: user_id}) do
      {:ok, pid} ->
        IO.puts "Starting game server"
        GameRuntime.live_state(pid)
      {:error, {:already_started, pid}} ->
        IO.puts "Noticed started game"
        GameRuntime.live_state(pid)
    end
  end

  def find_runtime(game_id) do
    {:via, Registry, {WordMaze.GameRegistry, game_id}}
  end













end
