defmodule WordMazeWeb.GameLive.Game do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.{ GameRuntime, RuntimeMonitor, Visibility, Letters }

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
        <%= live_component @socket, Board, spaces: @spaces, viewed_spaces: @viewed_spaces, players: @players, player_id: @player_id %>
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









  # Funcitons for movement

  def move_player(socket, key) do

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

    WordMazeWeb.Endpoint.broadcast("game:#{socket.assigns.game_id}", "client:move",  %{player_id: socket.assigns.player_id, direction: direction})
    resets =
      %{
        discarding: false,
        typing: false,
        word_input: nil
      }
    assign(socket, resets)
  end



  # Functions for word input

  # def toggle_typing(socket) do
  #   %{typing: typing, spaces: spaces, players: players, player_id: player_id} = socket.assigns
  #   case typing do
  #     true -> assign(socket, %{typing: false, word_input: nil})
  #     false ->
  #       visible = Visibility.visible_spaces(spaces, players[player_id].location)
  #       case Enum.all?(visible, fn address -> spaces[address].letter != nil end) do
  #         true  ->
  #           socket
  #         false ->
  #           data = initialize_typing_data(players, player_id, spaces)
  #           assign(socket, %{typing: true, word_input: data})
  #       end
  #   end
  # end

  # def initialize_typing_data(players, player_id, spaces) do

  #   {player_x, player_y} = player_location = players[player_id].location
  #   visible = Visibility.visible_spaces(spaces, player_location)

  #   horizontal =
  #     visible
  #     |> Enum.filter(fn address -> spaces[address].letter == nil end)
  #     |> Enum.all?(fn {_x, y} -> y == player_y end)

  #   start =
  #     case horizontal do
  #       true -> Enum.min_by(visible, fn {x, _y} -> x end)
  #       false -> Enum.min_by(visible, fn {_x, y} -> y end)
  #     end

  #   letters =
  #     case horizontal do
  #       true ->
  #         visible
  #         |> Enum.filter(fn {_x, y} -> y == player_y end)
  #         |> Enum.map(fn address ->
  #           case spaces[address].letter do
  #             nil -> nil
  #             letter -> String.upcase(letter)
  #           end
  #         end)
  #       false ->
  #         visible
  #         |> Enum.filter(fn {x, _y} -> x == player_x end)
  #         |> Enum.map(fn address ->
  #           case spaces[address].letter do
  #             nil -> nil
  #             letter -> String.upcase(letter)
  #           end
  #         end)
  #     end

  #   axis = if horizontal, do: :horizontal, else: :vertical

  #   {start, axis, letters}
  # end

  # def input_address(word_input) do
  #   {{x, y}, axis , letters} = word_input
  #   index = Enum.find_index(letters, fn letter -> letter == nil end)
  #   case { axis, index } do
  #     { _ , nil }       -> nil
  #     {:horizontal, _ } -> {x + index, y}
  #     {:vertical, _ }   -> {x, y + index}
  #   end
  # end

  # def handle_letter_input(letter, word_input, hand) do

  #   {start, axis, letters} = word_input

  #   played_letters =
  #     letters
  #     |> Enum.filter(fn letter -> Enum.member?(@alphabet, letter) end)

  #   available_letters = hand -- played_letters

  #   case Enum.member?(available_letters, letter) do
  #     true  ->
  #       case Enum.count(letters, fn l -> l == nil end) do
  #         0 ->
  #           # Come back to handle case of completed word

  #           word_input
  #         _ ->
  #           replace_index = Enum.find_index(letters, fn l -> l == nil end)
  #           Enum.find_index(letters, fn l -> l == nil end)
  #           new_letters = List.replace_at(letters, replace_index, letter)
  #           {start, axis, new_letters}
  #       end
  #     false -> word_input
  #   end

  # end

  def place_letter(hand_index, hand, location, spaces) do

    case spaces[location].letter == nil and not Enum.any?(hand, fn {_, l} -> l == location end) do
      true ->
        # Add check if submission should be attempted. Broadcast if true.
        {{letter, _}, rem} = List.pop_at(hand, hand_index)
        %{hand: List.replace_at(hand, hand_index, {letter, location})}
      false   -> %{}
    end

  end

  # Remove letter function, call on click and on appropriate move

  def unplace_letter(hand_index, hand) do
    {{letter, _}, rem} = List.pop_at(hand, hand_index)
    %{ hand: List.replace_at(hand, hand_index, {letter, nil})}
  end













  # Event handlers

  def handle_event("keydown", %{"key" => key}, socket) when key in @arrows do
    new_socket = move_player(socket, key)
    {:noreply, new_socket}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, socket}
  end

  # def handle_event("toggle-typing", _value, socket) do
  #   new_socket = toggle_typing(socket)
  #   {:noreply, new_socket}
  # end

  def handle_event("place-letter", %{"position" => position}, socket) do
    %{player_id: player_id, players: players, hand: hand, spaces: spaces} = socket.assigns
    {index, _} = Integer.parse(position)
    update = place_letter(index, hand, players[player_id].location, spaces)
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
