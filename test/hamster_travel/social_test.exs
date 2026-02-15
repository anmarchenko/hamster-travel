defmodule HamsterTravel.SocialTest do
  use HamsterTravel.DataCase, async: true

  alias HamsterTravel.Social

  describe "friendships" do
    import HamsterTravel.AccountsFixtures

    test "list_friend_ids/1 returns all friend ids for given user" do
      user = user_fixture()
      friend = user_fixture()
      assert {:ok, _} = Social.add_friends(user.id, friend.id)
      assert Social.list_friend_ids(friend.id) == [user.id]
    end

    test "add_friends/2 with valid data creates a two-way friendship" do
      user = user_fixture()
      friend = user_fixture()
      assert {:ok, _} = Social.add_friends(user.id, friend.id)
      assert Social.list_friend_ids(user.id) == [friend.id]
      assert Social.list_friend_ids(friend.id) == [user.id]
    end

    test "remove_friends/2 removes a two-way friendship" do
      user = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(user.id, friend.id)
      {:ok, _} = Social.remove_friends(friend.id, user.id)
      assert Social.list_friend_ids(user.id) == []
      assert Social.list_friend_ids(friend.id) == []
    end

    test "list_friends/1 returns friend users sorted by name" do
      user = user_fixture()
      alice = user_fixture(%{name: "Alice"})
      bob = user_fixture(%{name: "Bob"})

      {:ok, _} = Social.add_friends(user.id, bob.id)
      {:ok, _} = Social.add_friends(user.id, alice.id)

      assert [%{id: alice_id}, %{id: bob_id}] = Social.list_friends(user.id)
      assert alice_id == alice.id
      assert bob_id == bob.id
    end
  end
end
