defmodule HamsterTravel.PackingTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Packing

  describe "backpacks" do
    alias HamsterTravel.Packing.Backpack

    import HamsterTravel.PackingFixtures

    @invalid_attrs %{days: nil, name: nil, people: nil}

    test "list_backpacks/0 returns all backpacks" do
      backpack = backpack_fixture()
      assert Packing.list_backpacks() == [backpack]
    end

    test "get_backpack!/1 returns the backpack with given id" do
      backpack = backpack_fixture()
      assert Packing.get_backpack!(backpack.id) == backpack
    end

    test "create_backpack/1 with valid data creates a backpack" do
      valid_attrs = %{days: 42, name: "some name", people: 42}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs)
      assert backpack.days == 42
      assert backpack.name == "some name"
      assert backpack.people == 42
    end

    test "create_backpack/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Packing.create_backpack(@invalid_attrs)
    end

    test "update_backpack/2 with valid data updates the backpack" do
      backpack = backpack_fixture()
      update_attrs = %{days: 43, name: "some updated name", people: 43}

      assert {:ok, %Backpack{} = backpack} = Packing.update_backpack(backpack, update_attrs)
      assert backpack.days == 43
      assert backpack.name == "some updated name"
      assert backpack.people == 43
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
