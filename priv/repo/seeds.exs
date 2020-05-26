# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

import Ecto.Query

alias WordMaze.{Accounts, Gameplay}



# Users

{:ok, cindy} = Accounts.create_user(%{name: "Cindy"})

{:ok, dave} = Accounts.create_user(%{name: "Dave"})

{:ok, jones} = Accounts.create_user(%{name: "Jones"})


# Games and players

{:ok, game_1 } = Gameplay.create_game_by_user(cindy)

Gameplay.add_user_to_game(dave, game_1)

{:ok, game_2 } = Gameplay.create_game_by_user(dave)

Gameplay.add_user_to_game(jones, game_2)

Gameplay.create_game_by_user(jones)






IO.inspect WordMaze.Repo.all(from g in WordMaze.Gameplay.Game, preload: :players)

IO.inspect WordMaze.Repo.all(from u in WordMaze.Accounts.User, preload: :games)



# Gameplay.add_user_to_game(dave, game_1)

# {:ok, game_2} = Gameplay.create_game()
# Gameplay.add_user_to_game(cindy, game_2)
# Gameplay.add_user_to_game(jones, game_2)

# {:ok, game_3} = Gameplay.create_game()
# Gameplay.add_user_to_game(dave, game_3)









