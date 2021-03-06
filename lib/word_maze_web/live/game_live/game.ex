defmodule WordMazeWeb.GameLive.Game do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.{ GameRuntime, RuntimeMonitor, Visibility, Letters, Movement, Players }

  @arrows ["ArrowLeft", "ArrowDown", "ArrowUp", "ArrowRight", "w", "a", "s", "d"]

  @impl true
  def mount(_params, %{"game_id" => game_id, "player_id" => player_id}, socket) do

    case connected?(socket) do
      true ->
        WordMazeWeb.Endpoint.subscribe("game:#{game_id}")

        game_state = GameRuntime.get_player_state({:via, Registry, {WordMaze.GameRegistry, game_id}}, player_id)

        new_socket =
          socket
          |> assign(game_state)
          |> assign(Players.initialize_local_state(game_id, player_id, game_state))

        {:ok, new_socket}

      false -> {:ok, assign(socket, %{status: :connecting})}
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <%= case @status do %>
      <% :connecting -> %>
        <div class="ui-box menu-ui">Connecting...</div>
      <% :announcing -> %>
        <div class="ui-box menu-ui">
          <h3>Game About to Start</h3>
          <h1><%= @duration - 240 %></h1>
        </div>
      <% :running -> %>
        <%= live_component @socket, RunningGame,
          spaces: @spaces,
          viewed_spaces: @viewed_spaces,
          viewed_letters: @viewed_letters,
          players: @players,
          player_id: @player_id,
          hand: @hand,
          duration: @duration,
          messages: @messages
        %>
      <% :complete -> %>
        <%= live_component @socket, EndGame,
          players: @players,
          player_id: @player_id
        %>
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

  def handle_event("keydown", %{"key" => _key}, socket) do
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

  def handle_event("discard-letter", %{"position" => position}, socket) do
    {{letter, _} , new_hand} = List.pop_at(socket.assigns.hand, String.to_integer(position))

    WordMazeWeb.Endpoint.broadcast(
      "game:#{socket.assigns.game_id}", "client:discard",
      %{player_id: socket.assigns.player_id, letter: letter}
    )

    {:noreply, assign(socket, :hand, new_hand)}
  end




  # Message Handlers

  # Ignore messages sent from other clients
  def handle_info(%{event: "client:" <> _message }, socket) do
    {:noreply, socket}
  end

  # Ignore state updates until initial game state has been received
  def handle_info(%{event: _message}, %{assigns: %{status: :connecting}} = state) do
    {:noreply, state}
  end

  def handle_info(%{event: "server:movement", payload:
    %{player_id: moving_player_id,
      location: location,
      viewing_spaces: viewing_spaces,
      viewing_letters: viewing_letters}}, socket)
  do
    %{
      players: players,
      player_id: player_id,
      spaces: spaces,
      hand: hand,
      viewed_spaces: viewed_spaces,
      viewed_letters: viewed_letters
    } = socket.assigns

    new_players = Movement.process_new_location(players, moving_player_id, location)

    new_viewed_spaces =
      viewed_spaces
      |> Enum.concat(viewing_spaces)
      |> Enum.uniq()

    new_viewed_letters =
      viewed_letters
      |> Enum.concat(viewing_letters)
      |> Enum.uniq()

    new_socket =
      case moving_player_id == player_id do
        true ->
          new_hand = Letters.unplace_unviewed_letters(hand, spaces, location)
          assign(socket,
            players: new_players,
            viewed_spaces: new_viewed_spaces,
            viewed_letters: new_viewed_letters,
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
    event: "server:submission_success",
    payload: %{player_id: submitting_player_id, new_spaces: new_spaces, letters_used: letters_used, new_score: new_score, message: message, game_status: game_status}
  }, socket) do

    %{player_id: player_id, players: players, spaces: spaces, hand: hand, viewed_letters: viewed_letters, messages: messages} = socket.assigns

    indicies = Enum.map(letters_used, fn {_ , _ , idx} -> idx end)

    currently_visible = Visibility.visible_spaces(spaces, players[player_id].location)

    updated_viewed_letters =
      letters_used
      |> Enum.filter(fn { _ , letter_location, _ } ->  Enum.member?(currently_visible, letter_location) end)
      |> Enum.map(fn { _ , letter_location, _ } -> letter_location end)
      |> Enum.concat(viewed_letters)

    player = players[submitting_player_id]

    updated_players = Map.put(players, submitting_player_id, %{ player | score: new_score} )


    base_update = %{spaces: new_spaces, viewed_letters: updated_viewed_letters, players: updated_players, messages: [message | messages], status: game_status}
    update =
      case submitting_player_id == player_id do
        true  ->
          filtered_hand =
            hand
            |> Enum.with_index()
            |> Enum.filter(fn {_, idx} -> not Enum.member?(indicies, idx) end)
            |> Enum.map(fn {value, _} -> value end)

          Map.put(base_update, :hand, filtered_hand)
        false ->

          new_hand = Enum.map(hand, fn {let, loc} ->
            case loc do
              nil -> {let, nil}
              _   ->
                case new_spaces[loc].letter do
                  nil -> {let, loc}
                  _   -> {let, nil}
                end
            end
          end)

          Map.put(base_update, :hand, new_hand)
      end

    {:noreply, assign(socket, update)}
  end

  def handle_info(%{event: "server:submission_failure", payload: %{player_id: player_id}}, socket) do
    case player_id == socket.assigns.player_id do
      true  ->
        new_hand = Enum.map(socket.assigns.hand, fn {letter, _} -> {letter, nil} end)

        {:noreply, assign(socket, :hand, new_hand)}
      false -> {:noreply, socket}
    end
  end

  def handle_info(%{event: "server:new_letter", payload: %{player_id: player_id, letter: letter}}, socket) do

    case player_id == socket.assigns.player_id do
      true  -> {:noreply, assign(socket, :hand, Enum.concat(socket.assigns.hand, [Letters.add_to_hand(letter)]))}
      false -> {:noreply, socket}
    end

  end

  def handle_info(%{event: "server:timer_update", payload: %{duration: duration}}, socket) do
    {:noreply, assign(socket, :duration, duration)}
  end

  def handle_info(%{event: "server:game_start", payload: %{duration: duration}}, socket) do
    {:noreply, assign(socket, %{duration: duration, status: :running})}
  end

  def handle_info(%{event: "server:game_complete"}, socket) do
    {:noreply, assign(socket, :status, :complete)}
  end

end
