defmodule HamsterTravel.PackingTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Packing

  describe "backpacks" do
    alias HamsterTravel.Packing.{Backpack, Item, List}

    import HamsterTravel.PackingFixtures

    @invalid_attrs %{days: nil, name: nil, nights: nil}

    setup do
      user = HamsterTravel.AccountsFixtures.user_fixture()
      {:ok, user: user}
    end

    test "list_backpacks/1 returns all backpacks" do
      %{name: name, user_id: user_id} = backpack_fixture()
      assert [%Backpack{name: ^name}] = Packing.list_backpacks(%{id: user_id})
    end

    test "get_backpack!/1 returns the backpack with given id and preloads" do
      backpack = backpack_fixture()
      db_backpack = Packing.get_backpack!(backpack.id)
      assert [] == db_backpack.lists
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "get_backpack_by_slug/1 returns the backpack with given slug and preloads" do
      backpack = backpack_fixture()
      db_backpack = Packing.get_backpack_by_slug(backpack.slug, %{id: backpack.user_id})
      assert [] == db_backpack.lists
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "create_backpack/1 with valid data creates a backpack", %{user: user} do
      valid_attrs = %{days: 42, name: "some name", nights: 42}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)
      assert backpack.days == 42
      assert backpack.name == "some name"
      assert backpack.nights == 42
      assert backpack.slug == "some-name"
    end

    test "create_backpack/1 slugifies cyrillic backpack names", %{user: user} do
      valid_attrs = %{days: 42, name: "Амстердам", nights: 42}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)
      assert backpack.name == "Амстердам"
      assert backpack.slug == "amsterdam"
    end

    test "create_backpack/1 changes slug name in case it is occupied", %{user: user} do
      backpack = backpack_fixture(%{name: "name"})
      valid_attrs = %{days: 42, name: backpack.name, nights: 42}

      assert {:ok, %Backpack{} = new_backpack} = Packing.create_backpack(valid_attrs, user)
      assert new_backpack.name == "name"
      assert new_backpack.slug == "name-1"

      assert {:ok, %Backpack{} = newer_backpack} = Packing.create_backpack(valid_attrs, user)
      assert newer_backpack.name == "name"
      assert newer_backpack.slug == "name-2"
    end

    test "create_backpack/1 with invalid data returns error changeset", %{
      user: user
    } do
      assert {:error, %Ecto.Changeset{}} = Packing.create_backpack(@invalid_attrs, user)
    end

    test "create_backpack/1 with valid data and template creates a backpack with associations", %{
      user: user
    } do
      valid_attrs = %{days: 1, name: "some name", nights: 42, template: "test"}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)
      assert backpack.days == 1
      assert backpack.name == "some name"
      assert backpack.nights == 42
      assert backpack.slug == "some-name"

      backpack = Packing.get_backpack!(backpack.id)

      assert [
               %List{
                 name: "Hygiene",
                 items: [
                   %Item{
                     name: "Napkins",
                     count: 2
                   },
                   %Item{
                     name: "Toothpaste",
                     count: 83
                   },
                   %Item{
                     name: "Toothbrush",
                     count: 3
                   }
                 ]
               },
               %List{
                 name: "Docs",
                 items: [%Item{name: "Passports", count: 42}, %Item{name: "Insurance", count: 3}]
               },
               %List{name: "Clothes"}
             ] = backpack.lists
    end

    test "update_backpack/2 with valid data updates the backpack and the slug" do
      backpack = backpack_fixture()
      update_attrs = %{days: 43, name: "some updated name", nights: 43}

      assert {:ok, %Backpack{} = backpack} = Packing.update_backpack(backpack, update_attrs)
      assert backpack.days == 43
      assert backpack.name == "some updated name"
      assert backpack.nights == 43
      assert backpack.slug == "some-updated-name"
    end

    test "update_backpack/2 when there is slug collision finds valid slug" do
      backpack_fixture(%{name: "some name"})
      backpack = backpack_fixture(%{name: "name"})
      update_attrs = %{days: 43, name: "some name", nights: 43}

      assert {:ok, %Backpack{} = backpack} = Packing.update_backpack(backpack, update_attrs)
      assert backpack.name == "some name"
      assert backpack.slug == "some-name-1"
    end

    test "update_backpack/2 with invalid data returns error changeset" do
      backpack = backpack_fixture()
      assert {:error, %Ecto.Changeset{}} = Packing.update_backpack(backpack, @invalid_attrs)

      db_backpack = Packing.get_backpack!(backpack.id)
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "delete_backpack/1 deletes the backpack" do
      backpack = backpack_fixture()
      assert {:ok, %Backpack{}} = Packing.delete_backpack(backpack)
      assert_raise Ecto.NoResultsError, fn -> Packing.get_backpack!(backpack.id) end
    end

    test "change_backpack/1 returns a backpack changeset" do
      backpack = backpack_fixture()
      assert %Ecto.Changeset{} = Packing.change_backpack(backpack)
    end
  end
end
