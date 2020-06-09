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

  def place_player(player, user_controlled) do
  {x, y} = player.location
  location = "calc( #{x} * 200% + 50% ), calc( #{y} * 200% + 50% )"
  "border: 2px solid #{player.color};
   transform: translate(#{location}) scale(1.5);
   z-index: #{if user_controlled, do: 3, else: 2};
  "
  end

  def reveal_tile({x, y}) do
    "grid-area: #{y + 1} / #{x + 1} / #{y + 2} / #{x + 2};"
  end

  def light_translate({x, y}) do
    "transform: translate(calc(#{x - 5} / 11 * 100%), calc(#{y - 5}/ 11 * 100%))"
  end

  def view_path_cutout(spaces, {x, y} = location) do

    {up, right, down, left} = GameHelpers.view_distances(spaces, location)

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

  def display_letter_score(letter) do
    GameHelpers.letter_scores()[letter]
  end





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
    {:noreply, new_socket}
  end

  def handle_info(%{event: "server:new_player", payload: %{player: player, player_id: player_id} }, socket) do
    players = Map.put(socket.assigns.players, player_id, player)
    {:noreply, assign(socket, :players, players)}
  end







end
