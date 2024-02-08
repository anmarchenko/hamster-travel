defmodule HamsterTravel.Planning.Policy do
  import Ecto.Query, warn: false

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Social

  def authorized?(:edit, %Trip{} = trip, %User{} = user) do
    trip.author_id == user.id
  end

  def authorized?(:delete, %Trip{} = trip, %User{} = user) do
    trip.author_id == user.id
  end

  def authorized?(:copy, %Trip{} = trip, %User{} = user) do
    Social.user_in_friends_circle?(user, trip.author_id)
  end

  def user_scope(query, %User{} = user) do
    friends_circle = Social.extract_policy_user_ids(user)

    from(t in query, where: t.author_id in ^friends_circle or t.private == false)
  end
end
