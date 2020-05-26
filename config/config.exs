# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :word_maze,
  ecto_repos: [WordMaze.Repo]

# Configures the endpoint
config :word_maze, WordMazeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RFGUOYfMrV3Fi2p4du5LGDH0aJY71aK0riliuVuTs3MVr1uKTlgeRc7p6R6/lFtb",
  render_errors: [view: WordMazeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: WordMaze.PubSub,
  live_view: [signing_salt: "9DbPUlsM"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
