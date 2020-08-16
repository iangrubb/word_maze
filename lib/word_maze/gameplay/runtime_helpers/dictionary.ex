defmodule WordMaze.Gameplay.Dictionary do

  def lookup(word) do
    File.stream!("./lib/word_maze/gameplay/runtime_helpers/word_list.txt")
    |> Enum.map(fn word -> String.trim(word) end)
    |> Enum.member?(String.upcase(word))

  end

end
