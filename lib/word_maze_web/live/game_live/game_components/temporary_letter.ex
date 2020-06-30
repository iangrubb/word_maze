defmodule TemporaryLetter do

  use Phoenix.LiveComponent

  alias WordMaze.Gameplay.{ Letters }

  def render(assigns) do
    ~L"""
    <div class="letter board-letter temporary" >
      <%= determine_letter(@location, @hand) %>
      <span><span><%= display_letter_score(determine_letter(@location, @hand)) %></span></span>
    </div>
    """
  end

  def determine_letter(location, hand) do
    {letter, _} = Enum.find(hand, fn {let, loc} -> loc == location end)
    letter
  end

  def display_letter_score(letter) do
    Letters.scores()[letter]
  end

end
