defmodule WordMaze.Gameplay.Words do

  alias WordMaze.Gameplay.{ Dictionary, Letters }

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

  def word_score(submission, spaces) do
    Enum.reduce(submission, 0, fn ({letter, location, hand_index}, acc) ->
      multiplier =
        case hand_index do
          nil -> 1
          _   -> spaces[location].multiplier
        end
      IO.puts Letters.scores()[letter] * multiplier
      (Letters.scores()[letter] * multiplier ) + acc
    end)
  end

  def submissions_score(submissions, spaces) do

    submissions
    |> Enum.reduce(0, fn (submission, acc) ->
      word_score(submission, spaces) + acc
    end)

  end


  def update_spaces_for_submissions(submissions, spaces) do

    updates = Enum.map(submissions, fn submission -> add_submission(submission, spaces) end)

    updates =
    case updates do
      [ updates ]             -> updates
      [ updates1, updates2 ]  -> Map.merge(updates1, updates2)
    end

    Enum.reduce( spaces, %{}, fn ({ loc , space }, acc) ->
      case Map.fetch(updates, loc) do
        :error -> Map.put(acc, loc, space)
        {:ok, letter} -> Map.put(acc, loc, %{ space | letter: letter })
      end
    end)

  end


  def letters_used_by_submissions(submissions) do

    combined_submissions =
      case submissions do
        [ sub ]             -> sub
        [ sub1, sub2 ]  -> Map.merge(sub1, sub2)
      end

    combined_submissions
    |> Enum.filter(fn {_ , _ , idx} -> idx != nil end)

  end


  def player_after_submission(player, letters_used, added_score) do

    player
    |> Map.put(:letters, player.letters -- Enum.map(letters_used, fn {l , _ , _} -> l end))
    |> Map.put(:score, player.score + added_score)

  end


end
