defmodule WordMaze.Gameplay.Letters do

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

  def place_letter(hand_index, hand, location, spaces) do
    case spaces[location].letter == nil and not Enum.any?(hand, fn {_, l} -> l == location end) do
      true ->
        # Add check if submission should be attempted. Broadcast if true.
        {{letter, _}, rem} = List.pop_at(hand, hand_index)
        %{hand: List.replace_at(hand, hand_index, {letter, location})}
      false   -> %{}
    end
  end

  def unplace_letter(hand_index, hand) do
    {{letter, _}, rem} = List.pop_at(hand, hand_index)
    %{ hand: List.replace_at(hand, hand_index, {letter, nil})}
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



end
