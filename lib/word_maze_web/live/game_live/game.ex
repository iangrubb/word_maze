defmodule WordMazeWeb.GameLive.Game do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.{ GameRuntime, RuntimeMonitor, Visibility, Letters, Movement }

  @alphabet ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  @arrows ["ArrowLeft", "ArrowDown", "ArrowUp", "ArrowRight", "w", "a", "s", "d"]

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
              hand: Enum.map(game_state.hand, fn letter -> initialize_hand_letter(letter) end)
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

  def render(assigns) do
    ~L"""
    <%= if @connected do %>

      <div id="game-screen" phx-window-keydown="keydown" phx-throttle="100">
        <%= live_component @socket, Board, spaces: @spaces, viewed_spaces: @viewed_spaces, players: @players, player_id: @player_id, hand: @hand %>
      </div>

      <div id="game-letters">
        <%= for {{letter, location}, position} <- Enum.with_index(@hand) do %>
          <%= live_component @socket, HandLetter, location: location, letter: letter, position: position %>
        <% end %>
      </div>

      <div id="game-controls"></div>

      <div id="game-scores"></div>

    <% end %>
    """
  end



  def initialize_hand_letter(letter) do
    {letter, nil}
  end



  # Event handlers

  def handle_event("keydown", %{"key" => key}, socket) when key in @arrows do
    direction =
      case key do
        "ArrowLeft" -> :left
        "a"         -> :left
        "ArrowDown" -> :down
        "s"         -> :down
        "ArrowUp"   -> :up
        "w"         -> :up
        "ArrowRight"-> :right
        "d"         -> :right
      end
    %{player_id: player_id, game_id: game_id} = socket.assigns
    updates = Movement.attempt_movement(game_id, player_id, direction)
    {:noreply, assign(socket, updates)}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, socket}
  end

  def handle_event("place-letter", %{"position" => position}, socket) do
    %{player_id: player_id, players: players, hand: hand, spaces: spaces} = socket.assigns
    {index, _} = Integer.parse(position)
    update = Letters.place_letter(index, hand, players[player_id].location, spaces)
    { :noreply, assign(socket, update) }
  end

  def handle_event("unplace-letter", %{"position" => position}, socket) do
    {index, _} = Integer.parse(position)
    update = Letters.unplace_letter(index, socket.assigns.hand)
    { :noreply, assign(socket, update) }
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
      viewing_letters: viewing_letters}}, socket)
  do
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
