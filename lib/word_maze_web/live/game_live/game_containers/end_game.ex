defmodule EndGame do

  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <div id="end-game-display">
        <h2><%= outcome_message(@players, @player_id) %></h2>
        <%= for player <- ordered_players(@players) do %>
          <div><span><%= player.ranking %>.</span> <span><%= player.color %></span> <span><%= player.score %></span> </div>
        <% end %>
      </div>
    """
  end

  def outcome_message(players, player_id) do
    {_ , player} = Enum.max_by(players, fn {_, player} -> player.score end)
    high_score = player.score
    case high_score == players[player_id].score do
      true -> "You Win!"
      false -> "You Lose!"
    end
  end

  def ordered_players(players) do
    { ordered, _ , _, _ } =
      players
      |> Enum.sort_by(fn {_, player} -> -player.score end)
      |> Enum.reduce({[], nil, nil, nil}, fn {_, player}, {acc, lastRank, lastScore, idx} ->
        cond do
          lastRank == nil ->
            {[ Map.put(player, :ranking, 1)], 1, player.score, 1 }
          lastScore == player.score ->
            {[ Map.put(player, :ranking, lastRank) | acc ], lastRank, lastScore, idx + 1 }
          true ->
            {[ Map.put(player, :ranking, idx + 1) | acc ], idx + 1, player.score, idx + 1 }
        end
      end)
    Enum.reverse(ordered)
  end

end
