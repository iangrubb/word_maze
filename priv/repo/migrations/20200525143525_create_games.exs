defmodule WordMaze.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :status, :string

      timestamps()
    end

  end
end
