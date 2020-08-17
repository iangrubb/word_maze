defmodule WordMaze.Gameplay.Dictionary do

  def lookup(word) do

    File.stream!("./assets/static/word_list.txt")
    |> Enum.map(fn word -> String.trim(word) end)
    |> Enum.member?(String.upcase(word))

  end

end
