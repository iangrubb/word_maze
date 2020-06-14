defmodule BoardLetter do

  use Phoenix.LiveComponent

  alias WordMaze.Gameplay.{ Letters }

  def render(assigns) do
    ~L"""
    <div class="letter board-letter" >
      <%= @letter %>
      <span><span><%= display_letter_score(@letter) %></span></span>
    </div>
    """
  end

  def display_letter_score(letter) do
    Letters.scores()[letter]
  end

end
