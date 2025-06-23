defmodule HamsterTravel.PolicyTest do
  use HamsterTravel.DataCase, async: true

  import Ecto.Query, warn: false
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PackingFixtures

  alias HamsterTravel.Packing.{Backpack, Policy}
  alias HamsterTravel.Repo
  alias HamsterTravel.Social

  setup do
    author = user_fixture()
    friend = user_fixture()
    backpack = backpack_fixture(%{user_id: author.id})
    Social.add_friends(author.id, friend.id)

    %{
      author: Repo.preload(author, :friendships),
      friend: Repo.preload(friend, :friendships),
      backpack: backpack
    }
  end

  test "authorized?/3 :edit allows author", %{author: author, backpack: backpack} do
    assert Policy.authorized?(:edit, backpack, author)
  end

  test "authorized?/3 :edit disallows author's friend", %{
    friend: friend,
    backpack: backpack
  } do
    refute Policy.authorized?(:edit, backpack, friend)
  end

  test "authorized?/3 :edit disallows any user", %{
    backpack: backpack
  } do
    user = user_fixture()
    refute Policy.authorized?(:edit, backpack, user)
  end

  test "authorized?/3 :copy allows author", %{author: author, backpack: backpack} do
    assert Policy.authorized?(:copy, backpack, author)
  end

  test "authorized?/3 :copy allows author's friend", %{
    friend: friend,
    backpack: backpack
  } do
    assert Policy.authorized?(:copy, backpack, friend)
  end

  test "authorized?/3 :copy disallows any user", %{
    backpack: backpack
  } do
    user = user_fixture() |> Repo.preload(:friendships)
    refute Policy.authorized?(:copy, backpack, user)
  end

  test "authorized?/3 :delete allows author", %{author: author, backpack: backpack} do
    assert Policy.authorized?(:delete, backpack, author)
  end

  test "authorized?/3 :delete disallows author's friend", %{
    friend: friend,
    backpack: backpack
  } do
    refute Policy.authorized?(:delete, backpack, friend)
  end

  test "user_scope/2 returns backpacks from the whole friends circle", %{
    author: author,
    friend: friend
  } do
    query = from(b in Backpack, order_by: [desc: b.inserted_at])
    backpack_fixture(%{user_id: friend.id})
    assert [%Backpack{}, %Backpack{}] = query |> Policy.user_scope(author) |> Repo.all()
  end
end
