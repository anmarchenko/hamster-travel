defmodule HamsterTravel.Packing.Policy do
  import Ecto.Query, warn: false

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Packing.Backpack
  alias HamsterTravel.Social

  def authorized?(:edit, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end

  def authorized?(:delete, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end

  def authorized?(:copy, %Backpack{} = backpack, %User{} = user) do
    Social.user_in_friends_circle?(user, backpack.user_id)
  end

  def user_scope(query, %User{} = user) do
    friends_circle = Social.extract_policy_user_ids(user)

    from(b in query, where: b.user_id in ^friends_circle)
  end
end
