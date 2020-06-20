defmodule WordMaze.Gameplay.Movement do

  alias WordMaze.Gameplay.{ Visibility }

  def request_movement(game_id, player_id, direction) do
    WordMazeWeb.Endpoint.broadcast(
      "game:#{game_id}", "client:move",
      %{player_id: player_id, direction: direction}
    )
    %{}
  end

  def destination({x, y}, direction) do
    case direction do
      :left   -> {x - 1, y}
      :down   -> {x, y + 1}
      :up     -> {x, y - 1}
      :right  -> {x + 1, y}
    end
  end

  def attempt_move(spaces, players, game_id, player_id, direction) do

    {x, y} = players[player_id].location

    target = destination({x, y}, direction)

    case spaces[target].open do
      true ->

        player = players[player_id]

        viewing_spaces = Visibility.visible_spaces(spaces, target)
        viewing_letters = Enum.filter(viewing_spaces, fn address -> spaces[address].letter !== nil end)

        WordMazeWeb.Endpoint.broadcast("game:#{game_id}", "server:movement",
          %{ player_id: player_id,
            location: target,
            viewing_spaces: viewing_spaces,
            viewing_letters: viewing_letters
          }
        )
        new_player = %{ player | location: target }
        Map.put(players, player_id, new_player)
      false -> players
    end
  end

  def process_new_location(players, player_id, location) do
    player = players[player_id]
    new_player = %{ player | location: location}
    new_players = Map.put(players, player_id, new_player)
  end






end
