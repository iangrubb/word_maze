defmodule WordMaze.Gameplay.Movement do

  def attempt_movement(game_id, player_id, direction) do

    WordMazeWeb.Endpoint.broadcast(
      "game:#{game_id}", "client:move",
      %{player_id: player_id, direction: direction}
    )

    # Add update to return unviewed provisional letters to hand. But, only if successful...

    %{}
  end



end
