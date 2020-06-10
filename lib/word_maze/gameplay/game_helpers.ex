defmodule WordMaze.Gameplay.GameHelpers do


  def visibility_in_direction(spaces, location, direction), do: visibility_in_direction(spaces, location, direction, 0)

  defp visibility_in_direction(spaces, location, direction, acc) do

    {x, y} = location


    next_location =
      case direction do
        :up -> {x, y - 1}
        :right -> {x + 1, y}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
      end

    case spaces[next_location].open do
      true -> visibility_in_direction(spaces, next_location, direction, acc + 1)
      false -> acc
    end
  end

  def view_distances(spaces, location) do
    {visibility_in_direction(spaces, location, :up    ),
     visibility_in_direction(spaces, location, :right ),
     visibility_in_direction(spaces, location, :down  ),
     visibility_in_direction(spaces, location, :left  )}
  end

  def visible_spaces(spaces, location) do

    {up, right, down, left} = view_distances(spaces, location)
    {x, y} = location

    vertical_spaces = for n <- (y - up)..(y + down), do: {x, n}
    horizontal_spaces = for n <- (x - left)..(x + right), do: {n, y}

    Enum.uniq(vertical_spaces ++ horizontal_spaces)

  end

  def location_is_visible?(spaces, location) do
    case Enum.find(GameHelpers.visible_spaces(spaces, location), fn space -> spaces[space].letter == nil end) do
      nil -> "background: gray"
      _   -> "background: white"
    end
  end

  def letter_frequencies() do
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

  def letter_scores() do
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
