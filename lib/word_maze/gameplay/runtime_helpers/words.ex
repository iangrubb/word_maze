defmodule WordMaze.Gameplay.Words do

  def validate_submissions(submissions, spaces) do
    true
  end

  def add_submission(submission, spaces) do
    # Submission is array of { let, location, hand_idx | nil }


    submission
    |> Enum.filter(fn { _ , _ , hand_idx} -> hand_idx != nil end)
    |> Enum.reduce(%{}, fn ({ letter , location , _}, map) -> Map.put(map, location, letter) end)

  end

end
