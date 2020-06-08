defmodule WordMazeWeb.GameLive.Show do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.{ GameRuntime, RuntimeMonitor, GameHelpers }

  @impl true
  def mount(_params, %{"game_id" => game_id, "player_id" => player_id}, socket) do

    if connected?(socket) do

      WordMazeWeb.Endpoint.subscribe("game:#{game_id}")

      case RuntimeMonitor.new_connection(self(), player_id, game_id) do
        :full ->
          WordMazeWeb.Endpoint.unsubscribe("game:#{game_id}")
          {:ok, assign(socket, :connected, false)}
        game_state ->
          local_defaults =
            %{
              game_id: game_id,
              player_id: player_id,
              connected: true,
              typing: "",
              discarding: false
            }
          new_socket =
            socket
            |> assign(game_state)
            |> assign(local_defaults)
          {:ok, new_socket}
      end
    else
      {:ok, assign(socket, :connected, false)}
    end
  end


 # Functions for computing view properties

 def screen_scroll(location) do
  {x, y} = location
  x_translate =
    cond do
      x < 6 -> 0
      x > 17 -> 12
      true -> x - 5
    end
  y_translate =
    cond do
      y < 6 -> 0
      y > 17 -> 12
      true -> y - 5
    end
  "transform: translate(calc(#{x_translate}/11 * -50%), calc(#{y_translate}/11 * -50%))"
 end

 def place_player(player) do
  {x, y} = player.location
  location = "calc( #{x} * 200% + 50% ), calc( #{y} * 200% + 50% )"
  "background: #{player.color}; transform: translate(#{location});"
 end

 def reveal_tile(address) do
  {x, y} = address
  "grid-area: #{y + 1} / #{x + 1} / #{y + 2} / #{x + 2};"
 end










#  def light_path(player_x, player_y, blocks) do

#   {up, right, down, left} = light_dimensions(player_x, player_y, blocks)

#   "clip-path: polygon(
#     calc((5/11) * 100% - 4px)            calc((5/11) * 100% - 4px),
#     calc((5/11) * 100% - 4px)            calc((#{5 - up}/11) * 100% - 4px),
#     calc((6/11) * 100% + 4px)            calc((#{5 - up}/11) * 100% - 4px),
#     calc((6/11) * 100% + 4px)            calc((5/11) * 100% - 4px),
#     calc((#{6 + right}/11) * 100% + 4px) calc( 5 / 11 * 100% - 4px),
#     calc((#{6 + right}/11) * 100% + 4px) calc( 6 / 11 * 100% + 4px),
#     calc((6/11) * 100% + 4px)            calc((6/11) * 100% + 4px),
#     calc((6/11) * 100% + 4px)            calc((#{6 + down}/11) * 100% + 4px),
#     calc((5/11) * 100% - 4px)            calc((#{6 + down}/11) * 100% + 4px),
#     calc((5/11) * 100% - 4px)            calc((6/11) * 100% + 4px),
#     calc((#{5 - left}/11) * 100% - 4px)  calc((6/11) * 100% + 4px),
#     calc((#{5 - left}/11) * 100% - 4px)  calc((5/11) * 100% - 4px))
#   "

#  end

#  def light_translate(player_x, player_y) do

#   "calc(#{player_x - 5} / 11 * 100%), calc(#{player_y - 5}/ 11 * 100%)"

#  end






#  <div id="screen-overlay">
#         <div class="overlay-shadow"></div>
#         <div class="overlay-revealed">
#           <%= for {x, y} <- @viewed_spaces do %>
#             <div class="revealed-tile" style="grid-area:<%= y + 1 %>/<%= x + 1 %>/<%= y + 2 %>/<%= x + 2 %>;"></div>
#           <% end %>
#         </div>
#         <div class="overlay-light" style="transform: translate(<%= light_translate(  1   , 1) %>);">
#           <div class="overlay-light-contents" style="<%= light_path(   1   , 1, @spaces) %>" >
#           </div>
#         </div>
#       </div>






  # Event handlers

  @arrows ["ArrowLeft", "ArrowDown", "ArrowUp", "ArrowRight"]

  def handle_event("keydown", %{"key" => key}, socket) when key in @arrows do
    WordMazeWeb.Endpoint.broadcast("game:#{socket.assigns.game_id}", "client:move",  %{player_id: socket.assigns.player_id, direction: key})
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, socket}
  end




  # Message Handlers

  def handle_info(%{event: "client:" <> _message }, socket) do
    #Ignore any messages from clients
    {:noreply, socket}
  end

  def handle_info(%{event: "server:new_location", payload:
    %{player_id: player_id,
      location: location,
      viewing_spaces: viewing_spaces,
      viewing_letters: viewing_letters}}, socket) do

    player = socket.assigns.players[player_id]
    new_player = %{ player | location: location}
    new_players = Map.put(socket.assigns.players, player_id, new_player)

    new_socket =
      case socket.assigns.player_id == player_id do
        true ->
          viewed_spaces =
            socket.assigns.viewed_spaces
            |> Enum.concat(viewing_spaces)
            |> Enum.uniq()
          viewed_letters =
            socket.assigns.viewed_letters
            |> Enum.concat(viewing_letters)
            |> Enum.uniq()
          assign(socket, players: new_players, viewed_spaces: viewed_spaces, viewed_letters: viewed_letters)
        false ->
          assign(socket, :players, new_players)
      end

    IO.inspect new_socket.assigns.viewed_letters


    # %{
    #   player_id: player_id,
    #   location: target,
    #   viewing_spaces: viewing_spaces,
    #   viewing_letters: viewing_letters
    # }


    {:noreply, new_socket}
  end

  def handle_info(%{event: "server:new_player", payload: %{player: player, player_id: player_id} }, socket) do
    players = Map.put(socket.assigns.players, player_id, player)
    {:noreply, assign(socket, :players, players)}
  end













end
