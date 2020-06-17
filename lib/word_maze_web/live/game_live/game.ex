defmodule WordMazeWeb.GameLive.Game do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.{ GameRuntime, RuntimeMonitor, Visibility, Letters, Movement, Players }

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
          new_socket =
            socket
            |> assign(game_state)
            |> assign(Players.local_state(game_id, player_id, game_state.letters))
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
        <%= live_component @socket, Board,
          spaces: @spaces,
          viewed_spaces: @viewed_spaces,
          viewed_letters: @viewed_letters,
          players: @players,
          player_id: @player_id,
          hand: @hand
        %>
      </div>

      <div id="game-letters">
        <%= for {{letter, location}, position} <- Enum.with_index(@hand) do %>
          <%= live_component @socket, HandLetter, location: location, letter: letter, position: position %>
        <% end %>
      </div>

      <div id="game-controls"></div>

      <div id="game-scores">
        <%= for {_id, player} <- @players do %>
          <div style="color: <%= player.color %>"><%= player.score %></div>
        <% end %>
      </div>

    <% end %>
    """
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
    updates = Movement.request_movement(game_id, player_id, direction)
    {:noreply, assign(socket, updates)}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, socket}
  end

  def handle_event("place-letter", %{"position" => position}, socket) do
    %{player_id: player_id, players: players, hand: hand, spaces: spaces, game_id: game_id} = socket.assigns
    {index, _} = Integer.parse(position)
    update = Letters.place_letter(index, hand, players[player_id].location, spaces, game_id, player_id)
    { :noreply, assign(socket, update) }
  end

  def handle_event("unplace-letter", %{"position" => position}, socket) do
    {index, _} = Integer.parse(position)
    update = Letters.unplace_letter(index, socket.assigns.hand)
    { :noreply, assign(socket, update) }
  end



  # Message Handlers

  def handle_info(%{event: "client:" <> _message }, socket) do
    {:noreply, socket}
  end

  def handle_info(%{event: "server:movement", payload:
    %{player_id: moving_player_id,
      location: location,
      viewed_spaces: viewed_spaces,
      viewed_letters: viewed_letters}}, socket)
  do
    %{players: players, player_id: player_id, spaces: spaces, hand: hand} = socket.assigns
    new_players = Movement.process_new_location(players, moving_player_id, location)
    new_socket =
      case moving_player_id == player_id do
        true ->
          new_hand = Letters.unplace_unviewed_letters(hand, spaces, location)
          assign(socket,
            players: new_players,
            viewed_spaces: viewed_spaces,
            viewed_letters: viewed_letters,
            hand: new_hand)
        false ->
          assign(socket, :players, new_players)
      end
    {:noreply, new_socket}
  end

  def handle_info(%{event: "server:new_player", payload: %{player: player, player_id: player_id} }, socket) do
    players = Map.put(socket.assigns.players, player_id, player)
    {:noreply, assign(socket, :players, players)}
  end

  def handle_info(%{
    event: "server:announce_submission_success",
    payload: %{player_id: submitting_player_id, new_spaces: new_spaces, letters_used: letters_used}
  }, socket) do

    %{player_id: player_id, spaces: spaces, hand: hand} = socket.assigns

    indicies = Enum.map(letters_used, fn {_ , _ , idx} -> idx end)


    # letters_used has the locations of used letters, add these to viewed letters for all players who have those locations in view.





    update =
      case submitting_player_id == player_id do
        true  ->
          filtered_hand =
            hand
            |> Enum.with_index()
            |> Enum.filter(fn {_, idx} -> not Enum.member?(indicies, idx) end)
            |> Enum.map(fn {value, _} -> value end)

          %{spaces: new_spaces, hand: filtered_hand}
        false -> %{spaces: new_spaces}
      end

    {:noreply, assign(socket, update)}
  end







end
