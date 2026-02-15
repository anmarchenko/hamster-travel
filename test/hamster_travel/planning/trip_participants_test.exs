defmodule HamsterTravel.Planning.TripParticipantsTest do
  use HamsterTravel.DataCase

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.GeoFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo
  alias HamsterTravel.Social

  describe "participants management" do
    test "add_trip_participant/3 adds author's friend" do
      author = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, friend.id)
      trip = trip_fixture(author, %{})

      assert {:ok, updated_trip} = Planning.add_trip_participant(trip, author, friend.id)
      assert Enum.map(updated_trip.trip_participants, & &1.user_id) == [friend.id]
    end

    test "add_trip_participant/3 allows participant to invite another author's friend" do
      author = user_fixture()
      participant = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      {:ok, _} = Social.add_friends(author.id, friend.id)

      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, participant.id)

      assert {:ok, updated_trip} = Planning.add_trip_participant(trip, participant, friend.id)

      assert Enum.sort(Enum.map(updated_trip.trip_participants, & &1.user_id)) ==
               Enum.sort([participant.id, friend.id])
    end

    test "add_trip_participant/3 rejects actor who is not participant" do
      author = user_fixture()
      actor = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, actor.id)
      {:ok, _} = Social.add_friends(author.id, friend.id)

      trip = trip_fixture(author, %{})

      assert {:error, :not_participant} = Planning.add_trip_participant(trip, actor, friend.id)
    end

    test "add_trip_participant/3 rejects users outside author's friends circle" do
      author = user_fixture()
      outsider = user_fixture()
      trip = trip_fixture(author, %{})

      assert {:error, :not_in_author_friend_circle} =
               Planning.add_trip_participant(trip, author, outsider.id)
    end

    test "add_trip_participant/3 rejects duplicates" do
      author = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, friend.id)
      trip = trip_fixture(author, %{})
      {:ok, _} = Planning.add_trip_participant(trip, author, friend.id)

      assert {:error, :already_participant} =
               Planning.add_trip_participant(trip, author, friend.id)
    end

    test "remove_trip_participant/3 allows author to remove participant" do
      author = user_fixture()
      friend = user_fixture()
      {:ok, _} = Social.add_friends(author.id, friend.id)
      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, friend.id)

      assert {:ok, updated_trip} = Planning.remove_trip_participant(trip, author, friend.id)
      assert updated_trip.trip_participants == []
    end

    test "remove_trip_participant/3 allows participant to remove themselves" do
      author = user_fixture()
      participant = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, participant.id)

      assert {:ok, updated_trip} =
               Planning.remove_trip_participant(trip, participant, participant.id)

      assert updated_trip.trip_participants == []
    end

    test "remove_trip_participant/3 rejects participant removing another participant" do
      author = user_fixture()
      participant = user_fixture()
      other_participant = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)
      {:ok, _} = Social.add_friends(author.id, other_participant.id)
      trip = trip_fixture(author, %{})
      {:ok, trip} = Planning.add_trip_participant(trip, author, participant.id)
      {:ok, trip} = Planning.add_trip_participant(trip, author, other_participant.id)

      assert {:error, :not_allowed} =
               Planning.remove_trip_participant(trip, participant, other_participant.id)
    end

    test "remove_trip_participant/3 rejects author removal" do
      author = user_fixture()
      trip = trip_fixture(author, %{})

      assert {:error, :cannot_remove_author} =
               Planning.remove_trip_participant(trip, author, author.id)
    end
  end

  describe "participants visibility and stats" do
    test "participant can see private planned and draft trips after friendship is removed" do
      author = user_fixture()
      participant = user_fixture()
      outsider = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)

      planned_trip = trip_fixture(author, %{private: true, status: Trip.planned()})
      draft_trip = trip_fixture(author, %{private: true, status: Trip.draft()})
      _outsider_trip = trip_fixture(outsider, %{private: true, status: Trip.planned()})

      {:ok, _} = Planning.add_trip_participant(planned_trip, author, participant.id)
      {:ok, _} = Planning.add_trip_participant(draft_trip, author, participant.id)
      {:ok, _} = Social.remove_friends(author.id, participant.id)

      participant = Repo.preload(participant, :friendships, force: true)

      assert Planning.fetch_trip!(planned_trip.slug, participant).id == planned_trip.id
      assert Enum.map(Planning.list_plans(participant), & &1.id) |> Enum.member?(planned_trip.id)
      assert Enum.map(Planning.list_drafts(participant), & &1.id) |> Enum.member?(draft_trip.id)
    end

    test "profile_stats/1 includes finished trips where user participated" do
      geonames_fixture()
      city = HamsterTravel.Geo.find_city_by_geonames_id("2950159")

      author = user_fixture()
      participant = user_fixture()
      {:ok, _} = Social.add_friends(author.id, participant.id)

      trip = trip_fixture(author, %{status: Trip.finished()})
      {:ok, _} = Planning.create_destination(trip, %{city_id: city.id, start_day: 0, end_day: 1})
      {:ok, _} = Planning.add_trip_participant(trip, author, participant.id)
      {:ok, _} = Social.remove_friends(author.id, participant.id)

      participant = Repo.preload(participant, :friendships, force: true)
      stats = Planning.profile_stats(participant)

      assert stats.total_trips == 1
      assert stats.countries == 1
      assert stats.days_on_the_road == trip.duration

      assert Enum.any?(stats.visited_cities, fn city_stat ->
               city_stat.name == city.name and city_stat.country_iso == city.country_code
             end)
    end
  end
end
