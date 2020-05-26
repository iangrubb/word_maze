defmodule WordMaze.Repo.Migrations.CreateGameUsers do
  use Ecto.Migration

  def change do
    create table(:game_users) do
      add :game_id, references(:games, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:game_users, [:game_id])
    create index(:game_users, [:user_id])
  end
end
