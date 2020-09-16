defmodule WordMazeWeb.GameLive.Lobby do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay.RuntimeMonitor

  def mount(_params, %{"user" => user}, socket) do
    inital_state =
      %{user: user}
      |> Map.merge(not_searching_state())
    {:ok, assign(socket, inital_state)}
  end

  def render(assigns) do
    ~L"""
    <div class="ui-box menu-ui">

      <%= case @searching do %>
        <%= false -> %>
          <h2>Welcome!</h2>
          <h5>Rules:</h5>
          <ul class="menu-list">
            <li>Move with WASD or Arrow Keys</li>
            <li>Place a letter by standing on an empty space and clicking it in hand</li>
            <li>Letters are submitted when a player spells a word in a row or column</li>
            <li>Submitted words score points based on the letters used and letter score multipliers</li>
            <li>Win by scoring 150 points or having the most points after 4 minutes</li>
          </ul>
          <button phx-click="start-searching">Find a Game</button>
        <%= true -> %>
          <h3>Finding a game...</h3>
          <h5>Players:</h5>
          <ul class="menu-list">
            <%= for waiting_user <- @waiting_list do %>
              <li><%= waiting_user.name %></li>
            <% end %>
          </ul>
          <button phx-click="stop-searching">Cancel</button>
      <% end %>

    </div>
    """
  end



  def handle_event("start-searching", _ , socket) do

    %{user: user} = socket.assigns

    case RuntimeMonitor.searching(user) do
      {:waiting, list} ->
        {:noreply, assign(socket,  searching_state(list))}
      {:game_starting, game_id} ->
        {:noreply, redirect(socket, to: Routes.game_path(socket, :show, game_id))}
    end
  end

  def handle_event("stop-searching", _, socket) do
    %{user: user} = socket.assigns
    :ok = RuntimeMonitor.not_searching(user)
    {:noreply, assign(socket, not_searching_state())}
  end

  defp searching_state(list) do
    %{searching: true, waiting_list: list}
  end

  defp not_searching_state() do
    %{searching: false, waiting_list: nil}
  end


  # Socket Updates

  def handle_info(%{event: "list_update", payload: %{waiting: new_waiting_list}}, socket) do
    {:noreply, assign(socket, :waiting_list, new_waiting_list)}
  end


  def handle_info(%{event: "game_starting", payload: %{game_id: game_id}}, socket) do
    {:noreply, redirect(socket, to: Routes.game_path(socket, :show, game_id))}
  end

end
