defmodule WordMaze.Gameplay.Letters do

  alias WordMaze.Gameplay.Visibility

  def total(spaces, players) do

    hand_letters = Enum.flat_map(players, fn player -> player.hand end)
    board_letters =
      spaces
      |> Enum.filter(fn space -> space.letter != nil end)
      |> Enum.map(fn space -> space.letter end)

    Enum.concat(hand_letters, board_letters)
    |> Enum.reduce(%{}, fn (letter, acc) ->
        case Map.has_key?(acc, letter) do
          true -> Map.put(acc, letter, acc[letter] + 1)
          false -> Map.put(acc, letter, 1)
        end
      end)
  end

  def generate() do

    total =
      frequencies()
      |> Enum.reduce(0, fn ({_letter, count}, acc) -> acc + count end)

    value = :rand.uniform(total)

    {_acc, letter} =
      frequencies()
      |> Enum.reduce( {0, nil} , fn ({letter, count}, {acc, target}) ->
        cond do
          target != nil         -> {acc, target}
          acc + count >= value  -> {acc, letter}
          true                  -> {acc + count, nil}
        end
      end)

    letter
  end



  def add_to_hand(letter) do
    {letter, nil}
  end

  def initialize_hand(letters) do
    Enum.map(letters, fn letter -> add_to_hand(letter) end)
  end




  def complete_word?(letters) do
    Enum.count(letters) > 1 and not Enum.member?(letters, nil)
  end

  def letters_at_locations(locations, spaces, hand) do
    Enum.map(locations, fn location ->
      case { spaces[location].letter, Enum.find( Enum.with_index(hand), fn {{let, loc}, idx} -> loc == location end) } do
        { nil, nil }                -> nil
        { nil, {{let, _loc}, hand_idx} } -> { let, location, hand_idx }
        { let, _   }                -> { let, location, nil }
      end
    end)
  end

  def valid_location?(spaces, location, hand) do

    spaces[location].letter == nil and
    not Enum.any?(hand, fn {_, l} -> l == location end) and
    Enum.any?(Visibility.visible_spaces(spaces, location), fn loc -> spaces[loc].letter != nil end)

  end

  def place_letter(hand_index, hand, {x, y} = location, spaces, game_id, player_id) do

    # Only allow letter placement when there's at least one tile in the row or column.
    # Refactor into a valid_location? function

    case valid_location?(spaces, location, hand)  do
      true ->
        {{letter, _}, rem} = List.pop_at(hand, hand_index)
        new_hand = List.replace_at(hand, hand_index, {letter, location})

        {horizontal_locations, vertical_locations} = Visibility.visible_axes(spaces, location)
        horizontal_letters = letters_at_locations(horizontal_locations, spaces, new_hand)
        vertical_letters = letters_at_locations(vertical_locations, spaces, new_hand)

        case { complete_word?(horizontal_letters), complete_word?(vertical_letters) } do
          { false, false } ->
            %{hand: List.replace_at(hand, hand_index, {letter, location})}
          { horizontal_finished, vertical_finished } ->

            possible_horizontal_word = if horizontal_finished, do: [horizontal_letters] , else: []
            possible_vertical_word = if vertical_finished, do: [vertical_letters], else: []

            WordMazeWeb.Endpoint.broadcast(
              "game:#{game_id}", "client:submit_words",
              %{player_id: player_id, submissions: Enum.concat(possible_horizontal_word, possible_vertical_word)}
            )

            %{hand: List.replace_at(hand, hand_index, {letter, location})}
        end
      false -> %{}
    end
  end

  def unplace_letter(hand_index, hand) do
    {{letter, _}, rem} = List.pop_at(hand, hand_index)
    %{ hand: List.replace_at(hand, hand_index, {letter, nil})}
  end

  def unplace_unviewed_letters(hand, spaces, location) do

    visible_spaces = Visibility.visible_spaces(spaces, location)

    Enum.map(hand , fn {letter, location} ->
      case { location, Enum.member?(visible_spaces, location) } do
        { nil, _ }    -> { letter, location }
        { _ , true }  -> { letter, location }
        { _ , false } -> { letter, nil}
      end
    end)

  end


  def frequencies() do
    %{
      "a" => 9,
      "b" => 2,
      "c" => 2,
      "d" => 4,
      "e" => 12,
      "f" => 2,
      "g" => 3,
      "h" => 2,
      "i" => 9,
      "j" => 1,
      "k" => 1,
      "l" => 4,
      "m" => 2,
      "n" => 6,
      "o" => 8,
      "p" => 2,
      "q" => 1,
      "r" => 6,
      "s" => 4,
      "t" => 6,
      "u" => 4,
      "v" => 2,
      "w" => 2,
      "x" => 1,
      "y" => 2,
      "z" => 1,
    }
  end

  def scores() do
    %{
      "a" => 1,
      "b" => 3,
      "c" => 3,
      "d" => 2,
      "e" => 1,
      "f" => 4,
      "g" => 2,
      "h" => 4,
      "i" => 1,
      "j" => 6,
      "k" => 5,
      "l" => 1,
      "m" => 3,
      "n" => 1,
      "o" => 1,
      "p" => 3,
      "q" => 10,
      "r" => 1,
      "s" => 1,
      "t" => 1,
      "u" => 1,
      "v" => 4,
      "w" => 4,
      "x" => 6,
      "y" => 4,
      "z" => 10,
    }
  end

  @alphabet ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]



end
