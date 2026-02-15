defmodule HamsterTravel.Planning.PolicyTest do
  use HamsterTravel.DataCase, async: true

  import Ecto.Query
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Planning.TripParticipant
  alias HamsterTravel.Repo

  test "participant?/2 checks author, preloaded participants, and DB fallback" do
    author = user_fixture()
    participant = user_fixture()
    outsider = user_fixture()
    trip = trip_fixture(author, %{private: true})

    %TripParticipant{}
    |> TripParticipant.changeset(%{trip_id: trip.id, user_id: participant.id})
    |> Repo.insert!()

    trip_preloaded = Repo.preload(trip, trip_participants: :user)

    assert Policy.participant?(trip_preloaded, author)
    assert Policy.participant?(trip_preloaded, participant)
    assert Policy.participant?(trip, participant)
    refute Policy.participant?(trip, outsider)
  end

  test "user_trip_visibility_scope/2 includes private trips for participants" do
    author = user_fixture()
    participant = user_fixture() |> Repo.preload(:friendships)
    trip = trip_fixture(author, %{private: true})

    %TripParticipant{}
    |> TripParticipant.changeset(%{trip_id: trip.id, user_id: participant.id})
    |> Repo.insert!()

    query =
      from(t in Trip, where: t.id == ^trip.id)
      |> Policy.user_trip_visibility_scope(participant)

    assert Repo.one(query).id == trip.id
  end

  test "user_plans_scope/2 includes planned trips for participants" do
    author = user_fixture()
    participant = user_fixture() |> Repo.preload(:friendships)
    trip = trip_fixture(author, %{private: true, status: Trip.planned()})

    %TripParticipant{}
    |> TripParticipant.changeset(%{trip_id: trip.id, user_id: participant.id})
    |> Repo.insert!()

    query =
      from(t in Trip, where: t.status in [^Trip.planned(), ^Trip.finished()])
      |> Policy.user_plans_scope(participant)

    assert Enum.any?(Repo.all(query), &(&1.id == trip.id))
  end

  test "user_drafts_scope/2 includes draft trips for participants" do
    author = user_fixture()
    participant = user_fixture() |> Repo.preload(:friendships)
    trip = trip_fixture(author, %{private: true, status: Trip.draft()})
    _other_trip = trip_fixture(author, %{private: true, status: Trip.draft()})

    %TripParticipant{}
    |> TripParticipant.changeset(%{trip_id: trip.id, user_id: participant.id})
    |> Repo.insert!()

    query =
      from(t in Trip, where: t.status == ^Trip.draft())
      |> Policy.user_drafts_scope(participant)

    assert Enum.map(Repo.all(query), & &1.id) == [trip.id]
  end
end
