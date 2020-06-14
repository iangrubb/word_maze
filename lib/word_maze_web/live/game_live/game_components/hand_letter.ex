defmodule HandLetter do

  use Phoenix.LiveComponent

  alias WordMaze.Gameplay.{ Letters }

  def render(assigns) do
    ~L"""
    <div
      class="letter hand-letter"
      style="<%= location_style(@location) %>"
      phx-click="<%= click_event(@location) %>"
      phx-value-position="<%= @position %>"
    >
      <%= @letter %>
      <span><span><%= display_letter_score(@letter) %></span></span>
    </div>
    """
  end

  def display_letter_score(letter) do
    Letters.scores()[letter]
  end

  def click_event(location) do
    case location do
      nil -> "place-letter"
      _   -> "unplace-letter"
    end
  end

  def location_style(location) do
    case location do
      nil ->
        "
        background: rgb(34, 37, 48);
        color: rgb(227, 232, 238);
        box-shadow: 2px 2px 0 rgb(71, 73, 82);
        "
      _   ->
        "
        background: rgb(61, 62, 68);
        color: rgb(164, 171, 180);
        box-shadow: 2px 2px 0 rgb(44, 44, 46);
        "
    end
  end

end
