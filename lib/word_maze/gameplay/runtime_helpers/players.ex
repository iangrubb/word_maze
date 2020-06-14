defmodule WordMaze.Gameplay.Players do

  alias WordMaze.Gameplay.{ Letters, Visibility }

  def initialize(state, player_id) do

    defaults = %{
      score: 0,
    }

    player_state =
      defaults
      |> set_initial_location(Enum.count(state.players))
      |> set_color(Enum.count(state.players))
      |> set_initial_hand()
      |> set_initial_view(state.spaces)

    %{state | players: Map.put(state.players, player_id, player_state)}
  end

  def get_state(state, player_id) do
    player_data = state.players[player_id]

    %{
      spaces: state.spaces,
      hand: player_data.hand,
      viewed_spaces: player_data.viewed_spaces,
      viewed_letters: player_data.viewed_letters,
      players: Enum.reduce(state.players, %{}, fn ({player_id, data}, acc) ->
        Map.put(acc, player_id, %{ score: data.score, color: data.color, location: data.location})
      end )
    }
  end



  defp set_initial_location(player_state, player_count) do

    location =
      case player_count do
        0 -> {1, 1}
        1 -> {21, 21}
        2 -> {21, 1}
        3 -> {1, 21}
      end
    Map.put(player_state, :location, location)
  end

  defp set_color(player_state, player_count) do

    color =
      case player_count do
        0 -> "red"
        1 -> "blue"
        2 -> "green"
        3 -> "yellow"
      end
    Map.put(player_state, :color, color)

  end

  defp set_initial_hand(player_state) do
    hand =
      [1, 2, 3, 4, 5, 6]
      |> Enum.map(fn _n -> Letters.generate() end )
    Map.put(player_state, :hand, hand)
  end

  defp set_initial_view(player_state, spaces) do

    viewed_spaces = Visibility.visible_spaces(spaces, player_state.location)
    viewed_letters = Enum.filter(viewed_spaces, fn address -> spaces[address].letter !== nil end)

    player_state
    |> Map.put(:viewed_spaces, viewed_spaces)
    |> Map.put(:viewed_letters, viewed_letters)

  end

end
