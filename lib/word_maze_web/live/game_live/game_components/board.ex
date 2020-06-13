defmodule Board do

  use Phoenix.LiveComponent

  alias WordMaze.Gameplay.{ GameHelpers }

  def render(assigns) do
    ~L"""
    <div id="game-board" style="<%= screen_scroll( @players[@player_id].location ) %>">

      <%= for { _ , %{x: x, y: y, class: class, letter: letter} } <- @spaces do %>
        <div class="<%= class %>" style="grid-area:<%= y + 1 %>/<%= x + 1 %>/<%= y + 2 %>/<%= x + 2 %>;">
          <%= if letter != nil do %>
            <div class="letter board-letter"><%= letter %><span><span><%= display_letter_score(letter) %></span></span></div>
          <% end %>
        </div>
      <% end %>

      <%= for { player_id, player } <- @players do %>
        <div class="character" style="<%= place_player(player, @player_id == player_id) %>" id="<%= player_id %>"></div>
      <% end %>

      <div class="overlay-light" style="<%= light_translate(@players[@player_id].location) %>"></div>

      <%= live_component @socket, ScreenOverlay, spaces: @spaces, location: @players[@player_id].location , viewed_spaces: @viewed_spaces %>

    </div>
    """
  end

  def screen_scroll(location) do
    {x, y} = location
    x_translate =
      cond do
        x < 6 -> 0
        x > 17 -> 13
        true -> x - 5
      end
    y_translate =
      cond do
        y < 6 -> 0
        y > 17 -> 13
        true -> y - 5
      end
    "transform: translate(calc(#{x_translate}/23 * -100%), calc(#{y_translate}/23 * -100%))"
  end

  def display_letter_score(letter) do
    GameHelpers.letter_scores()[letter]
  end

  def place_player(player, user_controlled) do
    {x, y} = player.location
    location = "calc( #{x} * 200% + 50% ), calc( #{y} * 200% + 50% )"
    "border: 2px solid #{player.color};
    transform: translate(#{location}) scale(1.5);
    z-index: #{if user_controlled, do: 3, else: 2};
    "
  end

  def light_translate({x, y}) do
    "transform: translate(calc(#{x - 5} / 11 * 100%), calc(#{y - 5}/ 11 * 100%))"
  end


end
