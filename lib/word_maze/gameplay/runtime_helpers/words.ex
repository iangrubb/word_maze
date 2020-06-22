defmodule WordMaze.Gameplay.Words do

  alias WordMaze.Gameplay.Dictionary

  def validate_submissions(submissions, spaces) do

    Enum.all?(submissions, fn submission -> valid_submission?(submission, spaces) end)

  end

  def valid_submission?(submission, spaces) do

    sorted_submission = Enum.sort_by(submission, fn {_, {x, y} , _} -> x + y end)

    word =
      sorted_submission
      |> Enum.reduce("", fn ({letter, _ , _}, acc) -> acc <> letter end)

    Enum.all?(sorted_submission, fn {_, location , flag} -> flag == nil or spaces[location].letter == nil end) and Dictionary.lookup(word)
  end


  def add_submission(submission, spaces) do

    submission
    |> Enum.filter(fn { _ , _ , hand_idx} -> hand_idx != nil end)
    |> Enum.reduce(%{}, fn ({ letter , location , _}, map) -> Map.put(map, location, letter) end)

  end

end
