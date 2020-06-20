defmodule ScreenOverlay do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  alias WordMaze.Gameplay.{ Visibility, Letters }

  def render(assigns) do
    ~L"""
    <div id="screen-overlay" style="<%= view_path_cutout(@spaces, @location) %>" >
      <%= for address <- @viewed_spaces do %>
        <div class="revealed-space" style="<%= place_tile(address) %>">
          <%= if Enum.member?(@viewed_letters, address) do %>
            <div class="letter viewed-letter">
              <%= @spaces[address].letter %>
              <span><span><%= display_letter_score(@spaces[address].letter) %></span></span>
            </div>
          <% else %>
            <div class="revealed-tile"></div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def view_path_cutout(spaces, {x, y} = location) do
    {up, right, down, left} = Visibility.view_distances(spaces, location)
    "clip-path: polygon(
      calc((#{x}/23) * 100% - 4px)              0,
      0                                         0,
      0                                         100%,
      100%                                      100%,
      100%                                      0,
      calc((#{x}/23) * 100% - 4px)              0,
      calc((#{x}/23) * 100% - 4px)              calc((#{y - up}/23) * 100% - 4px),
      calc((#{x + 1}/23) * 100% + 4px)          calc((#{y - up}/23) * 100% - 4px),
      calc((#{x + 1}/23) * 100% + 4px)          calc((#{y}/23) * 100% - 4px),
      calc((#{x + 1 + right}/23) * 100% + 4px)  calc((#{y}/23) * 100% - 4px),
      calc((#{x + 1 + right}/23) * 100% + 4px)  calc((#{y + 1}/23) * 100% + 4px),
      calc((#{x + 1}/23) * 100% + 4px)          calc((#{y + 1}/23) * 100% + 4px),
      calc((#{x + 1}/23) * 100% + 4px)          calc((#{y + 1 + down}/23) * 100% + 4px),
      calc((#{x}/23) * 100% - 4px)              calc((#{y + 1 + down}/23) * 100% + 4px),
      calc((#{x}/23) * 100% - 4px)              calc((#{y + 1}/23) * 100% + 4px),
      calc((#{x - left}/23) * 100% - 4px)       calc((#{y + 1}/23) * 100% + 4px),
      calc((#{x - left}/23) * 100% - 4px)       calc((#{y}/23) * 100% - 4px),
      calc((#{x}/23) * 100% - 4px)              calc((#{y}/23) * 100% - 4px)
    )"
  end

  def place_tile({x, y}) do
    "grid-area: #{y + 1} / #{x + 1} / #{y + 2} / #{x + 2};"
  end

  def display_letter_score(letter) do
    Letters.scores()[letter]
  end

end
