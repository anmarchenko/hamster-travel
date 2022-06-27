defmodule HamsterTravel.PackingTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Packing

  describe "backpacks" do
    alias HamsterTravel.Packing.Backpack

    import HamsterTravel.PackingFixtures

    @invalid_attrs %{days: nil, name: nil, people: nil}

    setup do
      user = HamsterTravel.AccountsFixtures.user_fixture()
      {:ok, user: user}
    end

    test "list_backpacks/0 returns all backpacks" do
      backpack = backpack_fixture()
      assert Packing.list_backpacks() == [backpack]
    end

    test "get_backpack!/1 returns the backpack with given id" do
      backpack = backpack_fixture()
      assert Packing.get_backpack!(backpack.id) == backpack
    end

    test "create_backpack/1 with valid data creates a backpack", %{user: user} do
      valid_attrs = %{days: 42, name: "some name", people: 42, user_id: user.id}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs)
      assert backpack.days == 42
      assert backpack.name == "some name"
      assert backpack.people == 42
      assert backpack.slug == "some-name"
    end

    test "create_backpack/1 slugifies cyrillic backpack names", %{user: user} do
      valid_attrs = %{days: 42, name: "Амстердам", people: 42, user_id: user.id}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs)
      assert backpack.name == "Амстердам"
      assert backpack.slug == "amsterdam"
    end

    test "create_backpack/1 changes slug name in case it is occupied", %{user: user} do
      backpack = backpack_fixture(%{name: "name"})
      valid_attrs = %{days: 42, name: backpack.name, people: 42, user_id: user.id}

      assert {:ok, %Backpack{} = new_backpack} = Packing.create_backpack(valid_attrs)
      assert new_backpack.name == "name"
      assert new_backpack.slug == "name-1"

      assert {:ok, %Backpack{} = newer_backpack} = Packing.create_backpack(valid_attrs)
      assert newer_backpack.name == "name"
      assert newer_backpack.slug == "name-2"
    end

    test "create_backpack/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Packing.create_backpack(@invalid_attrs)
    end

    test "update_backpack/2 with valid data updates the backpack and the slug" do
      backpack = backpack_fixture()
      update_attrs = %{days: 43, name: "some updated name", people: 43}

      assert {:ok, %Backpack{} = backpack} = Packing.update_backpack(backpack, update_attrs)
      assert backpack.days == 43
      assert backpack.name == "some updated name"
      assert backpack.people == 43
      assert backpack.slug == "some-updated-name"
    end

    test "update_backpack/2 when there is slug collision finds valid slug" do
      backpack_fixture(%{name: "some name"})
      backpack = backpack_fixture(%{name: "name"})
      update_attrs = %{days: 43, name: "some name", people: 43}

      assert {:ok, %Backpack{} = backpack} = Packing.update_backpack(backpack, update_attrs)
      assert backpack.name == "some name"
      assert backpack.slug == "some-name-1"
    end

    test "update_backpack/2 with invalid data returns error changeset" do
      backpack = backpack_fixture()
      assert {:error, %Ecto.Changeset{}} = Packing.update_backpack(backpack, @invalid_attrs)
      assert backpack == Packing.get_backpack!(backpack.id)
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
