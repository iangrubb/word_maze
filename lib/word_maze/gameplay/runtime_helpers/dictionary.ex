defmodule WordMaze.Gameplay.Dictionary do

  def lookup(word) do
    value =

    File.stream!("#{File.cwd!()}/lib/word_maze/gameplay/runtime_helpers/word_list.txt")
    |> Enum.map(fn word -> String.trim(word) end)
    |> Enum.member?(String.upcase(word))

    IO.puts(value)

    value
  end

end
