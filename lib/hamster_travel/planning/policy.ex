defmodule HamsterTravel.Planning.Policy do
  import Ecto.Query, warn: false

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Social

  def authorized?(:edit, %Trip{} = trip, %User{} = user) do
    Social.user_in_friends_circle?(user, trip.author_id)
  end

  def authorized?(:delete, %Trip{} = trip, %User{} = user) do
    trip.author_id == user.id
  end

  def authorized?(:copy, %Trip{}, %User{}) do
    true
  end

  def user_trip_visibility_scope(query, %User{} = user) do
    friends_circle = Social.extract_policy_user_ids(user)

    # TODO: or if I am participant in the trip
    from(t in query, where: t.author_id in ^friends_circle or t.private == false)
  end

  def user_plans_scope(query, %User{} = user) do
    friends_circle = Social.extract_policy_user_ids(user)

    # TODO: or if I am participant in the trip
    from(t in query, where: t.author_id in ^friends_circle)
  end

  def user_drafts_scope(query, %User{} = user) do
    # TODO: or if I am participant in the trip
    from(t in query, where: t.author_id == ^user.id)
  end
end
