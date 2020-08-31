# WordMaze

A real-time multiplayer game inspired by Scrabble and old-school dungeon crawlers. Four players move around a maze discovering new locations and placing letters from their hands. New letters can be placed to connect to old letters, forming words that fill in the hallways of the maze. Players score points based on the words they play. The winner is either the first player to 150 points or the player with the highest number of points after four minutes.

This was my first project using Phoenix and I used this as an opportunity to play around with some of its more distinctive features, such as good support for real-time user interact, ability to hold application state in a long-running process rather than a database, and LiveView for server-based rendering that doesn't require writting JavaScript. I was especially curious to test out the latency of the game once deployed. I was a bit doubtful at first, but pleasently surpised to find that the game is pretty smooth provided a good home internet set-up and proximity to the server host. I haven't put much thought into how to reduce movement latency, but may come back to the project and do so in the future.

The game map itself is built purely with CSS, which was a fun challenge. By overlaying several kinds of element, playing a bit with opacity and clip path, and using some subtle gradients, I was able to build a map I was happy with without adding too much to the complexity of the program. I might eventually come back and remake this in canvas, but I don't have much experience using canvas and getting it working over LiveView seems tricky.

Game is live *[here](http://word-maze.gigalixirapp.com/)*. at time of writting, hosted through gigalixir on aws us-east-1.

## Tech Stack

- Elixir
- Phoenix
- Phoenix Channels
- Phoenix LiveView

## Known issues

- Players lose their knowledge of previously view locations if they reconnect to the game. The relevant state needs to be refactored to live in the game process itself, rather than in the user's LiveView process.
