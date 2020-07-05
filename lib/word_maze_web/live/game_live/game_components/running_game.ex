
defmodule RunningGame do

  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div id="game-screen" phx-window-keydown="keydown" phx-throttle="100">
        <div id="screen-border"></div>
        <%= live_component @socket, Board,
          spaces: @spaces,
          viewed_spaces: @viewed_spaces,
          viewed_letters: @viewed_letters,
          players: @players,
          player_id: @player_id,
          hand: @hand
        %>
      </div>

      <div class="ui-box" id="game-timer">
        <%= format_timer(@duration) %>
      </div>

      <div class="ui-box" id="game-messages" >
        <%= for message <- @messages do %>
          <div class="message" ><%= message %></div>
        <% end %>
      </div>

      <div class="ui-box" id="game-letters">
        <%= for {{letter, location}, position} <- Enum.with_index(@hand) do %>
          <%= live_component @socket, HandLetter, location: location, letter: letter, position: position %>
        <% end %>
      </div>

      <div class="ui-box" id="game-scores">
        <%= for {_id, player} <- @players do %>
          <%= live_component @socket, PlayerScore, player: player %>
        <% end %>
      </div>
    """
  end

  def format_timer(seconds) do
    case seconds do
      0 -> "DONE"
      _ ->
        min = div(seconds, 60)
        sec = rem(seconds, 60)
        format_sec =
          case sec > 9 do
            true -> "#{sec}"
            false -> "0#{sec}"
          end
        "#{min}:#{format_sec}"
    end
  end


end



