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
      |> set_initial_letters()

    %{state | players: Map.put(state.players, player_id, player_state)}
  end

  def get_state(state, player_id) do
    player_data = state.players[player_id]

    %{
      spaces: state.spaces,
      letters: player_data.letters,
      players: Enum.reduce(state.players, %{}, fn ({player_id, data}, acc) ->
        Map.put(acc, player_id, %{ score: data.score, color: data.color, location: data.location})
      end ),
      duration: state.duration
    }
  end

  def initialize_local_state(game_id, player_id, game_state) do

    %{letters: letters, spaces: spaces, players: players, duration: duration} = game_state

    viewed_spaces = Visibility.visible_spaces(spaces, players[player_id].location)

    %{
      game_id: game_id,
      player_id: player_id,
      connected: true,
      duration: duration,
      hand: Letters.initialize_hand(letters),
      viewed_spaces: viewed_spaces,
      viewed_letters: Enum.filter(viewed_spaces, fn address -> spaces[address].letter !== nil end),
      messages: []
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

  defp set_initial_letters(player_state) do
    letters =
      [1, 2, 3, 4, 5, 6, 7]
      |> Enum.map(fn _n -> Letters.generate() end )
    Map.put(player_state, :letters, letters)
  end


end
