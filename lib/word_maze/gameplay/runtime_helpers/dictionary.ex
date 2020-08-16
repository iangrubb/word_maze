defmodule WordMaze.Gameplay.Dictionary do

  def lookup(word) do

    path = Path.expand("./lib/word_maze/gameplay/runtime_helpers/word_list.txt") |> Path.absname

    File.stream!(path)
    |> Enum.map(fn word -> String.trim(word) end)
    |> Enum.member?(String.upcase(word))

  end

end
