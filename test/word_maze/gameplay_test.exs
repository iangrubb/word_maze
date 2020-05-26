defmodule WordMaze.GameplayTest do
  use WordMaze.DataCase

  alias WordMaze.Gameplay

  describe "games" do
    alias WordMaze.Gameplay.Game

    @valid_attrs %{status: "some status"}
    @update_attrs %{status: "some updated status"}
    @invalid_attrs %{status: nil}

    def game_fixture(attrs \\ %{}) do
      {:ok, game} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Gameplay.create_game()

      game
    end

    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Gameplay.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Gameplay.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      assert {:ok, %Game{} = game} = Gameplay.create_game(@valid_attrs)
      assert game.status == "some status"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gameplay.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      assert {:ok, %Game{} = game} = Gameplay.update_game(game, @update_attrs)
      assert game.status == "some updated status"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Gameplay.update_game(game, @invalid_attrs)
      assert game == Gameplay.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Gameplay.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Gameplay.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Gameplay.change_game(game)
    end
  end

  describe "game_users" do
    alias WordMaze.Gameplay.GameUser

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def game_user_fixture(attrs \\ %{}) do
      {:ok, game_user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Gameplay.create_game_user()

      game_user
    end

    test "list_game_users/0 returns all game_users" do
      game_user = game_user_fixture()
      assert Gameplay.list_game_users() == [game_user]
    end

    test "get_game_user!/1 returns the game_user with given id" do
      game_user = game_user_fixture()
      assert Gameplay.get_game_user!(game_user.id) == game_user
    end

    test "create_game_user/1 with valid data creates a game_user" do
      assert {:ok, %GameUser{} = game_user} = Gameplay.create_game_user(@valid_attrs)
    end

    test "create_game_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gameplay.create_game_user(@invalid_attrs)
    end

    test "update_game_user/2 with valid data updates the game_user" do
      game_user = game_user_fixture()
      assert {:ok, %GameUser{} = game_user} = Gameplay.update_game_user(game_user, @update_attrs)
    end

    test "update_game_user/2 with invalid data returns error changeset" do
      game_user = game_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Gameplay.update_game_user(game_user, @invalid_attrs)
      assert game_user == Gameplay.get_game_user!(game_user.id)
    end

    test "delete_game_user/1 deletes the game_user" do
      game_user = game_user_fixture()
      assert {:ok, %GameUser{}} = Gameplay.delete_game_user(game_user)
      assert_raise Ecto.NoResultsError, fn -> Gameplay.get_game_user!(game_user.id) end
    end

    test "change_game_user/1 returns a game_user changeset" do
      game_user = game_user_fixture()
      assert %Ecto.Changeset{} = Gameplay.change_game_user(game_user)
    end
  end
end
