defmodule HamsterTravel.Planning.Policy do
  import Ecto.Query, warn: false

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Planning.{Trip, TripParticipant}
  alias HamsterTravel.Repo
  alias HamsterTravel.Social

  def authorized?(:edit, %Trip{} = trip, %User{} = user) do
    Social.user_in_friends_circle?(user, trip.author_id) or participant?(trip, user)
  end

  def authorized?(:delete, %Trip{} = trip, %User{} = user) do
    trip.author_id == user.id
  end

  def authorized?(:copy, %Trip{}, %User{}) do
    true
  end

  def authorize_edit(%Trip{} = trip, %User{} = user) do
    if authorized?(:edit, trip, user) do
      :ok
    else
      {:error, "Unauthorized"}
    end
  end

  def user_trip_visibility_scope(query, nil) do
    from(t in query, where: t.private == false)
  end

  def user_trip_visibility_scope(query, %User{} = user) do
    friends_circle = Social.extract_policy_user_ids(user)
    participant_trip_ids = participant_trip_ids_subquery(user.id)

    from(t in query,
      where:
        t.author_id in ^friends_circle or t.id in subquery(participant_trip_ids) or
          t.private == false
    )
  end

  def user_plans_scope(query, nil) do
    from(t in query, where: t.private == false)
  end

  def user_plans_scope(query, %User{} = user) do
    friends_circle = Social.extract_policy_user_ids(user)
    participant_trip_ids = participant_trip_ids_subquery(user.id)

    from(t in query,
      where: t.author_id in ^friends_circle or t.id in subquery(participant_trip_ids)
    )
  end

  def user_drafts_scope(query, %User{} = user) do
    participant_trip_ids = participant_trip_ids_subquery(user.id)

    from(t in query, where: t.author_id == ^user.id or t.id in subquery(participant_trip_ids))
  end

  def participant?(%Trip{author_id: author_id}, %User{id: user_id}) when author_id == user_id do
    true
  end

  def participant?(%Trip{trip_participants: trip_participants, id: trip_id}, %User{id: user_id}) do
    if Ecto.assoc_loaded?(trip_participants) do
      Enum.any?(trip_participants, &(&1.user_id == user_id))
    else
      from(tp in TripParticipant, where: tp.trip_id == ^trip_id and tp.user_id == ^user_id)
      |> Repo.exists?()
    end
  end

  def participant?(%Trip{}, nil), do: false

  defp participant_trip_ids_subquery(user_id) when is_binary(user_id) do
    from(tp in TripParticipant, where: tp.user_id == ^user_id, select: tp.trip_id)
  end
end
