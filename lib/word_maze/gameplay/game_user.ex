defmodule WordMaze.Gameplay.GameUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "game_users" do
    field :game_id, :id, primary_key: true
    field :user_id, :id, primary_key: true
    # belongs_to :game, WordMaze.Gameplay.Game, primary_key: true
    # belongs_to :user, WordMaze.Accounts.User, primary_key: true

    timestamps()
  end

  @required_fields ~w(user_id project_id)a

  @doc false
  def changeset(game_user, attrs) do
    game_user
    |> cast(attrs, [:game_id, :user_id])
    |> validate_required([:game_id, :user_id])
  end
end
