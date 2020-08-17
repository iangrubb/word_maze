defmodule WordMaze.Gameplay.Dictionary do

  def lookup(word) do

    File.stream!("/app/lib/word_maze-0.1.0/priv/static/word_list.txt")
    |> Enum.map(fn word -> String.trim(word) end)
    |> Enum.member?(String.upcase(word))

  end

end
