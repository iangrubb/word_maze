defmodule WordMaze.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # WordMaze.Repo,
      # Start the Telemetry supervisor
      WordMazeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: WordMaze.PubSub},
      # Start game presence tracking
      WordMazeWeb.Presence,
      # Start the Endpoint (http/https)
      WordMazeWeb.Endpoint,
      # Start game live view monitor
      {WordMaze.Gameplay.RuntimeMonitor, name: WordMaze.Gameplay.RuntimeMonitor},
      # Start ongoing game registry
      {Registry, keys: :unique, name: WordMaze.GameRegistry},
      # Start game runtime supervisor
      {DynamicSupervisor, strategy: :one_for_one, name: WordMaze.GameRuntimeSupervisor}
      # Start a worker by calling: WordMaze.Worker.start_link(arg)
      # {WordMaze.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WordMaze.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WordMazeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
