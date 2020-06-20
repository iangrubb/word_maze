defmodule WordMaze.Gameplay.Words do

  def validate_submissions(submissions, spaces) do
    true
  end

  def add_submission(submission, spaces) do

    submission
    |> Enum.filter(fn { _ , _ , hand_idx} -> hand_idx != nil end)
    |> Enum.reduce(%{}, fn ({ letter , location , _}, map) -> Map.put(map, location, letter) end)

  end

end
