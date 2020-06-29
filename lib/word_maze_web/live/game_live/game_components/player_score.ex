defmodule PlayerScore do

  use Phoenix.LiveComponent

  alias WordMaze.Gameplay.{ Letters }

  def render(assigns) do
    ~L"""
    <div class="player-score">
      <h3 class="player-name"><%= @player.color %></h3>
      <div class="score-region">
        <div style="color: <%= @player.color %>" class="score"><%= @player.score %></div>
        <div class="score-bar">
        <div style="<%= determine_score_bar(@player) %>"></div>

        </div>
      </div>

    </div>
    """
  end

  def determine_score_bar(player) do
    "
    position: absolute;
    top: 0;
    bottom: 0;
    left: 0;
    right: #{100 - (player.score / 2) }%;
    background: #{player.color};
    transition: right 0.2s ease;
    border-radius: 2px 0 0 2px;
    "
  end


end

