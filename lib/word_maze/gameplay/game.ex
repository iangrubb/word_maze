defmodule WordMaze.Gameplay.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :status, :string
    many_to_many :players, WordMaze.Accounts.User, join_through: WordMaze.Gameplay.GameUser, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  def changeset_players(game, players) do
    game
    |> cast(%{}, [:status])
    |> put_assoc(:players, players)
  end

end
