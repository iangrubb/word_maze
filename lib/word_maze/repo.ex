defmodule WordMaze.Repo do
  use Ecto.Repo,
    otp_app: :word_maze,
    adapter: Ecto.Adapters.Postgres
end
