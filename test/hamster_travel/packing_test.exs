defmodule HamsterTravel.PackingTest do
  use HamsterTravel.DataCase, async: true

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.{Backpack, Item, List}
  alias HamsterTravel.Repo
  alias HamsterTravel.Social

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PackingFixtures

  describe "backpacks" do
    @invalid_attrs %{days: nil, name: nil, nights: nil}

    setup do
      user = user_fixture()
      friend = user_fixture()
      Social.add_friends(user.id, friend.id)
      {:ok, user: Repo.preload(user, :friendships), friend: Repo.preload(friend, :friendships)}
    end

    test "list_backpacks/1 returns all backpacks including ones from friends", %{
      user: user,
      friend: friend
    } do
      %{name: name} = backpack_fixture(%{user_id: user.id})
      %{name: friend_name} = backpack_fixture(%{user_id: friend.id})

      assert [%Backpack{name: ^friend_name}, %Backpack{name: ^name}] =
               Packing.list_backpacks(user)
    end

    test "get_backpack/1 returns the backpack with given id and preloads" do
      backpack = backpack_fixture()
      db_backpack = Packing.get_backpack(backpack.id)
      assert [] == db_backpack.lists
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "get_backpack/1 returns nil if backpack does not exist" do
      assert Packing.get_backpack(Ecto.UUID.generate()) == nil
    end

    test "get_backpack!/1 returns the backpack with given id and preloads" do
      backpack = backpack_fixture()
      db_backpack = Packing.get_backpack!(backpack.id)
      assert [] == db_backpack.lists
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "new_backpack/1 copies backpack into new changeset" do
      %Backpack{
        days: days,
        name: name,
        nights: nights
      } = backpack = backpack_fixture()

      expected_name = "#{name} (Copy)"

      new = Packing.new_backpack(backpack)

      assert %Ecto.Changeset{
               data: %{
                 id: nil,
                 days: ^days,
                 nights: ^nights,
                 name: ^expected_name
               }
             } = new
    end

    test "fetch_backpack!/2 returns the backpack with given slug and preloads", %{user: user} do
      backpack = backpack_fixture(%{user_id: user.id})
      db_backpack = Packing.fetch_backpack!(backpack.slug, user)
      assert [] == db_backpack.lists
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "fetch_backpack!/2 returns the backpack from friend", %{
      user: user,
      friend: friend
    } do
      backpack = backpack_fixture(%{user_id: friend.id})
      db_backpack = Packing.fetch_backpack!(backpack.slug, user)
      assert [] == db_backpack.lists
      assert backpack.name == db_backpack.name
    end

    test "create_backpack/2 with valid data creates a backpack", %{user: user} do
      valid_attrs = %{days: 42, name: "some name", nights: 42}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)
      assert backpack.days == 42
      assert backpack.name == "some name"
      assert backpack.nights == 42
      assert backpack.slug == "some-name"
    end

    test "create_backpack/2 slugifies cyrillic backpack names", %{user: user} do
      valid_attrs = %{days: 42, name: "Амстердам", nights: 42}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)
      assert backpack.name == "Амстердам"
      assert backpack.slug == "amsterdam"
    end

    test "create_backpack/2 changes slug name in case it is occupied", %{user: user} do
      backpack = backpack_fixture(%{name: "name"})
      valid_attrs = %{days: 42, name: backpack.name, nights: 42}

      assert {:ok, %Backpack{} = new_backpack} = Packing.create_backpack(valid_attrs, user)
      assert new_backpack.name == "name"
      assert new_backpack.slug != backpack.slug

      assert {:ok, %Backpack{} = newer_backpack} = Packing.create_backpack(valid_attrs, user)
      assert newer_backpack.name == "name"
      assert newer_backpack.slug != new_backpack.slug
    end

    test "create_backpack/2 with invalid data returns error changeset", %{
      user: user
    } do
      assert {:error, %Ecto.Changeset{}} = Packing.create_backpack(@invalid_attrs, user)
    end

    test "create_backpack/2 with valid data and template creates a backpack with associations", %{
      user: user
    } do
      valid_attrs = %{days: 1, name: "some name", nights: 42, template: "test"}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)
      assert backpack.days == 1
      assert backpack.name == "some name"
      assert backpack.nights == 42
      assert backpack.slug == "some-name"

      backpack = Packing.get_backpack!(backpack.id)

      # sorted correctly
      assert ["Hygiene", "Docs", "Clothes"] = Enum.map(backpack.lists, fn list -> list.name end)
      refute Enum.any?(backpack.lists, fn list -> list.rank == nil end)

      hygiene_items =
        backpack.lists
        |> Enum.filter(fn list -> list.name == "Hygiene" end)
        |> Enum.flat_map(fn list -> list.items end)

      refute Enum.any?(hygiene_items, fn item -> item.rank == nil end)

      assert [
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
             ] = hygiene_items

      docs_items =
        backpack.lists
        |> Enum.filter(fn list -> list.name == "Docs" end)
        |> Enum.flat_map(fn list -> list.items end)
        |> Enum.sort_by(fn item -> item.name end)

      assert [%Item{name: "Insurance", count: 3}, %Item{name: "Passports", count: 42}] =
               docs_items
    end

    test "create_backpack/3 with valid data creates a backpack copying associations from existing",
         %{
           user: user
         } do
      backpack = backpack_fixture()
      {:ok, list} = Packing.create_list(%{name: "L"}, backpack)
      {:ok, item} = Packing.create_item(%{name: "I 3"}, list)
      Packing.update_item_checked(item, true)
      backpack = Packing.get_backpack!(backpack.id)

      valid_attrs = %{days: 1, name: "some new name", nights: 42, template: "test"}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user, backpack)
      assert backpack.days == 1
      assert backpack.name == "some new name"
      assert backpack.nights == 42
      assert backpack.slug == "some-new-name"

      new_backpack = Packing.get_backpack!(backpack.id)

      assert ["L"] = Enum.map(new_backpack.lists, fn list -> list.name end)

      items =
        new_backpack.lists
        |> Enum.flat_map(fn list -> list.items end)

      assert [
               %Item{
                 name: "I",
                 count: 3,
                 checked: false
               }
             ] = items
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
      assert backpack.slug != "some-name"
    end

    test "update_backpack/2 with invalid data returns error changeset" do
      backpack = backpack_fixture()
      assert {:error, %Ecto.Changeset{}} = Packing.update_backpack(backpack, @invalid_attrs)

      db_backpack = Packing.get_backpack!(backpack.id)
      assert backpack.name == db_backpack.name
      assert backpack.days == db_backpack.days
      assert backpack.nights == db_backpack.nights
    end

    test "delete_backpack/1 deletes the backpack with associations", %{
      user: user
    } do
      initial_items_count = Repo.one(from(i in "backpack_items", select: count(i.id)))
      initial_lists_count = Repo.one(from(i in "backpack_lists", select: count(i.id)))

      valid_attrs = %{days: 1, name: "some name", nights: 42, template: "test"}
      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)

      assert {:ok, %Backpack{}} = Packing.delete_backpack(backpack)
      assert_raise Ecto.NoResultsError, fn -> Packing.get_backpack!(backpack.id) end

      assert initial_items_count == Repo.one(from(i in "backpack_items", select: count(i.id)))
      assert initial_lists_count == Repo.one(from(i in "backpack_lists", select: count(i.id)))
    end

    test "change_backpack/1 returns a backpack changeset" do
      backpack = backpack_fixture()
      assert %Ecto.Changeset{} = Packing.change_backpack(backpack)
    end

    test "count_backpacks/0 returns the number of backpacks" do
      initial_count = Packing.count_backpacks()
      backpack = backpack_fixture()
      assert initial_count + 1 == Packing.count_backpacks()
      Packing.delete_backpack(backpack)
      assert initial_count == Packing.count_backpacks()
    end
  end

  describe "items" do
    setup do
      list = list_fixture()
      item = item_fixture()
      {:ok, list: list, item: item}
    end

    @invalid_attrs %{name: nil, count: nil}

    test "create_item/2 creates a new valid item", %{list: list} do
      {:ok, item} = Packing.create_item(%{name: "toothbrush", count: 3}, list)
      refute item.checked
      assert "toothbrush" = item.name
      assert 3 = item.count
    end

    test "create_item/2 sends pubsub event", %{list: list} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{list.backpack_id}")

      {:ok, item} = Packing.create_item(%{name: "toothbrush", count: 3}, list)
      assert_received {[:item, :created], %{value: ^item}}
    end

    test "create_item/2 returns errors if item is invalid", %{list: list} do
      assert {:error, %Ecto.Changeset{}} = Packing.create_item(@invalid_attrs, list)
    end

    test "create_item/2 parses name if count is not provided to get count", %{list: list} do
      {:ok, item} = Packing.create_item(%{name: "toothbrush a b 3"}, list)
      refute item.checked
      assert "toothbrush a b" = item.name
      assert 3 = item.count
    end

    test "create_item/2 correctly processes trailing whitespaces", %{list: list} do
      {:ok, item} = Packing.create_item(%{name: "toothbrush a b 3           "}, list)
      refute item.checked
      assert "toothbrush a b" = item.name
      assert 3 = item.count
    end

    test "create_item/2 works with string keys too", %{list: list} do
      {:ok, item} = Packing.create_item(%{"name" => "toothbrush 3"}, list)
      refute item.checked
      assert "toothbrush" = item.name
      assert 3 = item.count
    end

    test "create_item/2 uses 1 as default count if not provided", %{list: list} do
      {:ok, item} = Packing.create_item(%{name: "toothbrush"}, list)
      refute item.checked
      assert "toothbrush" = item.name
      assert 1 = item.count
    end

    test "create_item/2 uses 1 as default count if cannot be parsed as int", %{list: list} do
      {:ok, item} = Packing.create_item(%{name: "toothbrush a b c d"}, list)
      refute item.checked
      assert "toothbrush a b c d" = item.name
      assert 1 = item.count
    end

    test "create_item/2 adds an item to the end of lists", %{list: list} do
      {:ok, item} = Packing.create_item(%{name: "socks"}, list)
      {:ok, item2} = Packing.create_item(%{name: "pants"}, list)

      assert item.rank < item2.rank
    end

    test "create_item/2 adds an item to the end of items even when there are template items already" do
      user = user_fixture()
      valid_attrs = %{days: 1, name: "backpack", nights: 2, template: "test"}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)

      list = Enum.at(backpack.lists, 0)

      {:ok, item} = Packing.create_item(%{name: "creme"}, list)
      {:ok, item2} = Packing.create_item(%{name: "stuff"}, list)

      assert item.rank < item2.rank
    end

    test "update_item_checked/2 sets checked property for item" do
      item = item_fixture()
      {:ok, item} = Packing.update_item_checked(item, true)
      assert item.checked
      {:ok, item} = Packing.update_item_checked(item, false)
      refute item.checked
    end

    test "update_item_checked/2 sends pubsub broadcast" do
      backpack = backpack_fixture()
      list = list_fixture(%{backpack_id: backpack.id})
      item = item_fixture(%{backpack_list_id: list.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      {:ok, item} = Packing.update_item_checked(item, true)
      assert_received {[:item, :updated], %{value: ^item}}
    end

    test "update_item/2 updates name and count", %{item: item} do
      assert {:ok, updated_item} = Packing.update_item(item, %{name: "Keks", count: 101})
      assert "Keks" = updated_item.name
      assert 101 = updated_item.count
    end

    test "update_item/2 sends pubsub braodcast" do
      backpack = backpack_fixture()
      list = list_fixture(%{backpack_id: backpack.id})
      item = item_fixture(%{backpack_list_id: list.id})

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      assert {:ok, updated_item} = Packing.update_item(item, %{name: "Keks", count: 101})
      assert_received {[:item, :updated], %{value: ^updated_item}}
    end

    test "update_item/2 returns errors when invalid attrs submitted", %{item: item} do
      assert {:error, %Ecto.Changeset{}} = Packing.update_item(item, @invalid_attrs)
    end

    test "update_item/2 parses name and count", %{item: item} do
      assert {:ok, updated_item} = Packing.update_item(item, %{name: "Keks 102"})
      assert "Keks" = updated_item.name
      assert 102 = updated_item.count
    end

    test "delete_item/1 deletes an item", %{item: item} do
      assert {:ok, deleted_item} = Packing.delete_item(item)
      assert nil == Repo.get(Item, deleted_item.id)
    end

    test "delete_item/1 sends pubsub event" do
      backpack = backpack_fixture()
      list = list_fixture(%{backpack_id: backpack.id})
      item = item_fixture(%{backpack_list_id: list.id})

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      {:ok, deleted_item} = Packing.delete_item(item)
      assert_received {[:item, :deleted], %{value: ^deleted_item}}
    end

    test "move_item_to_list/3 moves an item to a different list" do
      backpack = backpack_fixture()
      list1 = list_fixture(%{backpack_id: backpack.id, name: "Clothes"})
      list2 = list_fixture(%{backpack_id: backpack.id, name: "Electronics"})
      item = item_fixture(%{backpack_list_id: list1.id, name: "T-shirt"})

      assert {:ok, moved_item} = Packing.move_item_to_list(item, list2.id, 1)
      assert moved_item.backpack_list_id == list2.id
      assert moved_item.position == 1
      assert moved_item.name == "T-shirt"
    end

    test "move_item_to_list/3 updates item position and rank correctly" do
      backpack = backpack_fixture()
      list1 = list_fixture(%{backpack_id: backpack.id})
      list2 = list_fixture(%{backpack_id: backpack.id})

      # Create 3 items in list2 first
      {:ok, existing_item1} = Packing.create_item(%{name: "Item 1"}, list2)
      {:ok, existing_item2} = Packing.create_item(%{name: "Item 2"}, list2)
      {:ok, existing_item3} = Packing.create_item(%{name: "Item 3"}, list2)

      # Create item to move in list1
      item = item_fixture(%{backpack_list_id: list1.id})

      # Move item to position 2 in list2 (between item1 and item2)
      assert {:ok, moved_item} = Packing.move_item_to_list(item, list2.id, 2)

      # Verify the item was moved correctly
      assert moved_item.backpack_list_id == list2.id
      assert moved_item.position == 2

      # Verify ordering is maintained - moved item should be in second position
      updated_backpack = Packing.get_backpack!(backpack.id)
      updated_list2 = Enum.find(updated_backpack.lists, &(&1.id == list2.id))
      items_by_rank = Enum.sort_by(updated_list2.items, & &1.rank)

      assert length(items_by_rank) == 4
      assert Enum.at(items_by_rank, 0).id == existing_item1.id
      assert Enum.at(items_by_rank, 1).id == existing_item2.id
      assert Enum.at(items_by_rank, 2).id == moved_item.id
      assert Enum.at(items_by_rank, 3).id == existing_item3.id
    end

    test "move_item_to_list/3 sends pubsub event" do
      backpack = backpack_fixture()
      list1 = list_fixture(%{backpack_id: backpack.id})
      list2 = list_fixture(%{backpack_id: backpack.id})
      item = item_fixture(%{backpack_list_id: list1.id})

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      {:ok, moved_item} = Packing.move_item_to_list(item, list2.id, 1)
      assert_received {[:item, :moved], %{value: ^moved_item}}
    end

    test "move_item_to_list/3 returns error for invalid list_id" do
      item = item_fixture()
      invalid_list_id = Ecto.UUID.generate()

      assert {:error, %Ecto.Changeset{}} = Packing.move_item_to_list(item, invalid_list_id, 1)
    end

    test "reorder_item/2 changes item position within same list" do
      list = list_fixture()

      # Create multiple items
      {:ok, _item1} = Packing.create_item(%{name: "First"}, list)
      {:ok, _item2} = Packing.create_item(%{name: "Second"}, list)
      {:ok, item3} = Packing.create_item(%{name: "Third"}, list)

      # Get original rank of item3
      original_rank = item3.rank

      # Move item3 to position 1 (second position)
      assert {:ok, reordered_item} = Packing.reorder_item(item3, 1)
      assert reordered_item.position == 1
      assert reordered_item.backpack_list_id == list.id

      # Verify the item's rank has changed (moved to earlier position)
      assert reordered_item.rank != original_rank

      # Verify exact ordering - item3 should now be in the middle
      updated_backpack = Packing.get_backpack!(list.backpack_id)
      updated_list = Enum.find(updated_backpack.lists, &(&1.id == list.id))
      items_by_rank = Enum.sort_by(updated_list.items, & &1.rank)

      assert length(items_by_rank) == 3
      assert Enum.at(items_by_rank, 1).id == item3.id
    end

    test "reorder_item/2 sends pubsub event" do
      backpack = backpack_fixture()
      list = list_fixture(%{backpack_id: backpack.id})
      item = item_fixture(%{backpack_list_id: list.id})

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      {:ok, reordered_item} = Packing.reorder_item(item, 2)
      assert_received {[:item, :moved], %{value: ^reordered_item}}
    end

    test "reorder_item/2 handles position at end of list" do
      list = list_fixture()
      {:ok, item1} = Packing.create_item(%{name: "First"}, list)
      {:ok, _item2} = Packing.create_item(%{name: "Second"}, list)

      # Move item1 to last position
      assert {:ok, reordered_item} = Packing.reorder_item(item1, 2)
      assert reordered_item.position == 2

      # Verify exact ordering - item1 should now be last
      updated_backpack = Packing.get_backpack!(list.backpack_id)
      updated_list = Enum.find(updated_backpack.lists, &(&1.id == list.id))
      items_by_rank = Enum.sort_by(updated_list.items, & &1.rank)

      assert length(items_by_rank) == 2
      assert Enum.at(items_by_rank, -1).id == item1.id
    end
  end

  describe "lists" do
    setup do
      backpack = backpack_fixture()
      list = list_fixture(%{backpack_id: backpack.id})
      {:ok, list: list, backpack: backpack}
    end

    @invalid_attrs %{name: nil}

    test "create_list/2 creates a new valid list", %{backpack: backpack} do
      {:ok, list} = Packing.create_list(%{name: "clothes"}, backpack)
      assert "clothes" = list.name
    end

    test "create_list/2 adds a list to the end of lists", %{backpack: backpack} do
      {:ok, list} = Packing.create_list(%{name: "clothes"}, backpack)
      {:ok, list2} = Packing.create_list(%{name: "tools"}, backpack)

      assert list.rank < list2.rank
    end

    test "create_list/2 adds a list to the end of lists even when there are template lists already" do
      user = user_fixture()
      valid_attrs = %{days: 1, name: "backpack", nights: 2, template: "test"}

      assert {:ok, %Backpack{} = backpack} = Packing.create_backpack(valid_attrs, user)

      {:ok, list} = Packing.create_list(%{name: "e"}, backpack)
      {:ok, list2} = Packing.create_list(%{name: "r"}, backpack)

      assert list.rank < list2.rank
    end

    test "create_list/2 sends pubsub event", %{backpack: backpack} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      {:ok, list} = Packing.create_list(%{name: "clothes"}, backpack)
      assert_received {[:list, :created], %{value: ^list}}
    end

    test "create_list/2 returns errors if attrs are invalid", %{backpack: backpack} do
      assert {:error, %Ecto.Changeset{}} = Packing.create_list(@invalid_attrs, backpack)
    end

    test "update_list/2 updates name", %{list: list} do
      assert {:ok, updated_list} = Packing.update_list(list, %{name: "Hygiene items"})
      assert "Hygiene items" = updated_list.name
    end

    test "update_list/2 sends pubsub braodcast", %{backpack: backpack, list: list} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      assert {:ok, updated_list} = Packing.update_list(list, %{name: "Food"})
      assert_received {[:list, :updated], %{value: ^updated_list}}
    end

    test "update_list/2 returns errors when invalid attrs submitted", %{list: list} do
      assert {:error, %Ecto.Changeset{}} = Packing.update_list(list, @invalid_attrs)
    end

    test "delete_list/1 deletes a list", %{list: list} do
      assert {:ok, deleted_list} = Packing.delete_list(list)
      assert nil == Repo.get(List, deleted_list.id)
    end

    test "delete_list/1 sends pubsub event", %{list: list, backpack: backpack} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks" <> ":#{backpack.id}")

      {:ok, deleted_list} = Packing.delete_list(list)
      assert_received {[:list, :deleted], %{value: ^deleted_list}}
    end
  end
end
