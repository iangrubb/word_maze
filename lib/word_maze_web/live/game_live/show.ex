defmodule WordMazeWeb.GameLive.Show do
  use WordMazeWeb, :live_view

  alias WordMaze.Gameplay
  alias WordMaze.Gameplay.GameRuntime
  alias WordMazeWeb.GameLive.Monitor

  @impl true
  def mount(_params, %{"game_id" => game_id, "player_id" => player_id}, socket) do

    if connected?(socket) do

      game_state = Monitor.new_connection(self(), player_id, game_id)

      WordMazeWeb.Endpoint.subscribe("game:server:#{game_id}")


      # Ideally the monitor would be the one looking for games without live servers and would shut them down after an appropriate period of time.


      new_socket =
        socket
        |> assign(game_state)
        |> new_ui()


      # Assigns
        # Blocks
        # Player Locations
        # Revealed Blocks

      # Events
        # Movement

      # Updates
        #

      # The whole game state should be updated by the runtime and sent here, where more about the view logic is determined.
        # In progress words don't need to interact with the runtime, or facts about what a player currently sees.
        # What a player can see and what there is should be put together here to determine what's displayed.



      {:ok, new_socket}
    else
      {:ok, assign(socket, :connected, false)}
    end


  end



 # Functions for computing derived data

 def passable_space(x, y, blocks, direction), do: passable_space(x, y, blocks, direction, 0)

 def passable_space(x, y, blocks, direction, acc) do

  {next_x, next_y} = next_location =
    case direction do
      :up -> {x, y - 1}
      :right -> {x + 1, y}
      :down -> {x, y + 1}
      :left -> {x - 1, y}
    end

  case blocks[next_location].passable do

    true -> passable_space(next_x, next_y, blocks, direction, acc + 1)
    false -> acc

  end

 end

 def light_dimensions(player_x, player_y, blocks) do

  {passable_space(player_x, player_y, blocks, :up),
  passable_space(player_x, player_y, blocks, :right),
  passable_space(player_x, player_y, blocks, :down),
  passable_space(player_x, player_y, blocks, :left)}

 end

 def light_path(player_x, player_y, blocks) do

  {up, right, down, left} = light_dimensions(player_x, player_y, blocks)

  "clip-path: polygon(
    calc((5/11) * 100% - 4px)            calc((5/11) * 100% - 4px),
    calc((5/11) * 100% - 4px)            calc((#{5 - up}/11) * 100% - 4px),
    calc((6/11) * 100% + 4px)            calc((#{5 - up}/11) * 100% - 4px),
    calc((6/11) * 100% + 4px)            calc((5/11) * 100% - 4px),
    calc((#{6 + right}/11) * 100% + 4px) calc( 5 / 11 * 100% - 4px),
    calc((#{6 + right}/11) * 100% + 4px) calc( 6 / 11 * 100% + 4px),
    calc((6/11) * 100% + 4px)            calc((6/11) * 100% + 4px),
    calc((6/11) * 100% + 4px)            calc((#{6 + down}/11) * 100% + 4px),
    calc((5/11) * 100% - 4px)            calc((#{6 + down}/11) * 100% + 4px),
    calc((5/11) * 100% - 4px)            calc((6/11) * 100% + 4px),
    calc((#{5 - left}/11) * 100% - 4px)  calc((6/11) * 100% + 4px),
    calc((#{5 - left}/11) * 100% - 4px)  calc((5/11) * 100% - 4px))
  "

 end

 def light_translate(player_x, player_y) do

  "calc(#{player_x - 5} / 11 * 100%), calc(#{player_y - 5}/ 11 * 100%)"

 end

 def character_translate(player_x, player_y) do
  "calc( #{player_x} * 200% + 50% ), calc( #{player_y} * 200% + 50% )"
 end







  # Event handlers

  @arrows ["ArrowLeft", "ArrowDown", "ArrowUp", "ArrowRight"]

  def handle_event("keydown", %{"key" => key}, socket) when key in @arrows do

    # Move the player on the game server, but also calls light_dimensions to add to a map of seen tiles.

    new_socket =
      socket
      |> move(key, socket.assigns.player_x, socket.assigns.player_y)
      |> add_revealed_blocks()

    {:noreply, new_socket}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, socket}
  end





  # UI logic that pertains to just the view of a single player

  def new_ui(socket) do

    defaults = %{
      revealed_blocks: [],
      connected: true
    }

    socket
    |> assign(defaults)
    |> add_revealed_blocks()

  end

  def add_revealed_blocks(socket) do
    %{player_x: player_x, player_y: player_y, blocks: blocks, revealed_blocks: revealed_blocks} = socket.assigns
    {up, right, down, left} = light_dimensions(player_x, player_y, blocks)

    vertical_blocks = for n <- (player_y - up)..(player_y + down), do: {player_x, n}
    horizontal_blocks = for n <- (player_x - left)..(player_x + right), do: {n, player_y}

    new_revealed_blocks =
      revealed_blocks
      |> Enum.concat(vertical_blocks)
      |> Enum.concat(horizontal_blocks)
      |> Enum.uniq()

    assign(socket, :revealed_blocks, new_revealed_blocks)
  end











  # Game logic, eventually should get moved to separate gen process

  defp move(socket, "ArrowLeft", x, y) do
    case socket.assigns.blocks[{x - 1, y}].passable do
        true -> assign(socket, :player_x, x - 1)
        false -> socket
    end
  end

  defp move(socket, "ArrowDown", x, y) do
    case socket.assigns.blocks[{x, y + 1}].passable do
      true -> assign(socket, :player_y, y + 1)
      false -> socket
    end
  end

  defp move(socket, "ArrowUp", x, y) do
    case socket.assigns.blocks[{x, y - 1}].passable do
      true -> assign(socket, :player_y, y - 1)
      false -> socket
    end
  end

  defp move(socket, "ArrowRight", x, y) do
    case socket.assigns.blocks[{x + 1, y}].passable do
      true -> assign(socket, :player_x, x + 1)
      false -> socket
    end
  end

  defp move(socket, _, x, y), do: socket







end
