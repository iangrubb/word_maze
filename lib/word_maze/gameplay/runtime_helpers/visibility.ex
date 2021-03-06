defmodule WordMaze.Gameplay.Visibility do

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

  def visible_axes(spaces, {x, y}) do

    visible = visible_spaces(spaces, {x, y})

    { Enum.filter(visible, fn {sx, sy} -> sy == y end), Enum.filter(visible, fn {sx, sy} -> sx == x end) }

  end



end
