defmodule HamsterTravel.PlanningTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Planning
  alias HamsterTravel.Social

  describe "trips" do
    alias HamsterTravel.Planning.Trip

    import HamsterTravel.AccountsFixtures
    import HamsterTravel.PlanningFixtures

    setup do
      user = user_fixture()
      friend = user_fixture()
      Social.add_friends(user.id, friend.id)
      {:ok, user: Repo.preload(user, :friendships), friend: Repo.preload(friend, :friendships)}
    end

    test "list_plans/1 returns all planned and finished trips including ones from friends", %{
      user: user,
      friend: friend
    } do
      %{id: first_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.planned(),
          start_date: ~D[2023-06-12],
          end_date: ~D[2023-06-13]
        })

      %{id: second_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.planned(),
          start_date: ~D[2023-03-01],
          end_date: ~D[2023-03-02]
        })

      %{id: friend_id} = trip_fixture(%{author_id: friend.id, status: Trip.finished()})
      %{id: _draft_id} = trip_fixture(%{author_id: user.id, status: Trip.draft()})

      assert [
               %Trip{id: ^first_id},
               %Trip{id: ^second_id},
               %Trip{id: ^friend_id}
             ] =
               Planning.list_plans(user)
    end

    test "list_drafts/1 returns all drafts for user", %{
      user: user,
      friend: friend
    } do
      %{id: first_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.draft(),
          name: "a"
        })

      %{id: second_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.draft(),
          name: "b"
        })

      %{id: _friend_id} = trip_fixture(%{author_id: friend.id, status: Trip.draft()})
      %{id: _plan_id} = trip_fixture(%{author_id: user.id, status: Trip.planned()})

      assert [
               %Trip{id: ^first_id},
               %Trip{id: ^second_id}
             ] =
               Planning.list_drafts(user)
    end

    test "get_trip/1 returns the trip with given id" do
      trip = trip_fixture()
      db_trip = Planning.get_trip(trip.id)
      assert trip.name == db_trip.name
    end

    test "get_trip/1 returns nil if trip does not exist" do
      assert Planning.get_trip(Ecto.UUID.generate()) == nil
    end

    test "get_trip!/1 returns the trip with given id" do
      trip = trip_fixture()
      assert Planning.get_trip!(trip.id).name == trip.name
    end

    test "fetch_trip!/2 returns public trip for unauthorized user" do
      trip = trip_fixture()
      assert Planning.fetch_trip!(trip.slug, nil).id == trip.id
    end

    test "fetch_trip!/2 raises when unauthorized user requests private trip" do
      trip = trip_fixture(%{private: true})

      assert_raise Ecto.NoResultsError, fn ->
        Planning.fetch_trip!(trip.slug, nil)
      end
    end

    test "fetch_trip!/2 returns own private trip", %{user: user} do
      trip = trip_fixture(%{private: true, author_id: user.id})
      assert Planning.fetch_trip!(trip.slug, user).id == trip.id
    end

    test "fetch_trip!/2 returns friends private trip", %{user: user, friend: friend} do
      trip = trip_fixture(%{private: true, author_id: friend.id})
      assert Planning.fetch_trip!(trip.slug, user).id == trip.id
    end

    test "fetch_trip!/2 returns other user's public trip", %{user: user} do
      trip = trip_fixture()
      assert Planning.fetch_trip!(trip.slug, user).id == trip.id
    end

    test "fetch_trip!/2 raises when fetching other user's private trip", %{
      user: user
    } do
      trip = trip_fixture(%{private: true})

      assert_raise Ecto.NoResultsError, fn ->
        Planning.fetch_trip!(trip.slug, user).id
      end
    end

    test "new_trip/1 returns a new trip changeset" do
      planned = Trip.planned()

      assert %Ecto.Changeset{
               data: %{
                 status: ^planned,
                 people_count: 2,
                 private: false,
                 currency: "EUR"
               }
             } =
               Planning.new_trip()
    end

    test "new_trip/1 with parameters returns a new trip changeset overriding fields from params" do
      draft = Trip.draft()

      assert %Ecto.Changeset{
               data: %{
                 status: ^draft,
                 people_count: 2,
                 private: false,
                 currency: "EUR"
               }
             } =
               Planning.new_trip(%{status: draft})
    end

    test "create_trip/2 with valid data creates a trip", %{user: user} do
      valid_attrs = %{
        name: "Venice on weekend",
        dates_unknown: false,
        duration: 0,
        start_date: ~D[2023-06-12],
        end_date: ~D[2023-06-14],
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 2
      }

      assert {:ok, %Trip{} = trip} = Planning.create_trip(valid_attrs, user)
      assert trip.name == "Venice on weekend"
      assert trip.slug == "venice-on-weekend"
      assert trip.currency == "EUR"
      assert trip.dates_unknown == false
      assert trip.duration == 3
      assert trip.start_date == ~D[2023-06-12]
      assert trip.end_date == ~D[2023-06-14]
      assert trip.status == "1_planned"
      assert trip.people_count == 2
      assert trip.private == false
      assert trip.author_id == user.id
    end

    test "create_trip/2 changes slug in case it is occupied", %{user: user} do
      trip = trip_fixture(%{name: "name"})

      valid_attrs = %{
        name: "name",
        dates_unknown: false,
        start_date: ~D[2023-06-12],
        end_date: ~D[2023-06-14],
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 2
      }

      assert {:ok, %Trip{} = new_trip} = Planning.create_trip(valid_attrs, user)
      assert new_trip.name == "name"
      assert new_trip.slug != trip.slug

      assert {:ok, %Trip{} = newer_trip} = Planning.create_trip(valid_attrs, user)
      assert newer_trip.name == "name"
      assert newer_trip.slug != new_trip.slug
    end

    test "create_trip/2 with unknown dates", %{user: user} do
      valid_attrs = %{
        name: "Venice on weekend",
        dates_unknown: true,
        duration: 1,
        start_date: ~D[2023-06-12],
        end_date: ~D[2023-06-14],
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 2
      }

      assert {:ok, %Trip{} = trip} = Planning.create_trip(valid_attrs, user)
      assert trip.name == "Venice on weekend"
      assert trip.slug == "venice-on-weekend"
      assert trip.currency == "EUR"
      assert trip.dates_unknown == true
      assert trip.duration == 1
      assert trip.start_date == nil
      assert trip.end_date == nil
      assert trip.status == "1_planned"
      assert trip.people_count == 2
      assert trip.private == false
      assert trip.author_id == user.id
    end

    test "create_trip/2 with empty name returns error changeset", %{user: user} do
      invalid_attrs = %{
        name: nil,
        dates_unknown: false,
        start_date: ~D[2023-06-12],
        end_date: ~D[2023-06-14],
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 2
      }

      assert {:error, %Ecto.Changeset{}} = Planning.create_trip(invalid_attrs, user)
    end

    test "create_trip/2 with unknown dates when duration is invalid", %{user: user} do
      invalid_attrs = %{
        name: "Venice on weekend",
        dates_unknown: true,
        duration: 0,
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 2
      }

      assert {:error, %Ecto.Changeset{}} = Planning.create_trip(invalid_attrs, user)
    end

    test "create_trip/2 with invali people_count", %{user: user} do
      invalid_attrs = %{
        name: "Venice on weekend",
        dates_unknown: true,
        duration: 1,
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 0
      }

      assert {:error, %Ecto.Changeset{}} = Planning.create_trip(invalid_attrs, user)
    end

    test "update_trip/2 with valid data updates the trip" do
      trip = trip_fixture()

      update_attrs = %{
        name: "Venice on weekend shorter",
        end_date: ~D[2023-06-13]
      }

      assert {:ok, %Trip{} = trip} = Planning.update_trip(trip, update_attrs)
      assert trip.name == "Venice on weekend shorter"
      assert trip.slug == "venice-on-weekend-shorter"
      assert trip.duration == 2
      assert trip.start_date == ~D[2023-06-12]
      assert trip.end_date == ~D[2023-06-13]
    end

    test "update_trip/2 with valid data updates the trip start_date" do
      trip = trip_fixture()

      update_attrs = %{
        name: "Venice on weekend longer",
        start_date: ~D[2023-06-10]
      }

      assert {:ok, %Trip{} = trip} = Planning.update_trip(trip, update_attrs)
      assert trip.name == "Venice on weekend longer"
      assert trip.slug == "venice-on-weekend-longer"
      assert trip.duration == 5
      assert trip.start_date == ~D[2023-06-10]
      assert trip.end_date == ~D[2023-06-14]
    end

    test "update_trip/2 with valid data updates the trip start_date and end_date" do
      trip = trip_fixture()

      update_attrs = %{
        name: "Venice on weekend one day",
        start_date: ~D[2023-04-23],
        end_date: ~D[2023-04-23]
      }

      assert {:ok, %Trip{} = trip} = Planning.update_trip(trip, update_attrs)
      assert trip.name == "Venice on weekend one day"
      assert trip.slug == "venice-on-weekend-one-day"
      assert trip.duration == 1
      assert trip.start_date == ~D[2023-04-23]
      assert trip.end_date == ~D[2023-04-23]
    end

    test "update_trip/2 with valid data updates the trip and sets unknown dates" do
      trip = trip_fixture()

      update_attrs = %{
        name: "Venice on weekend maybe",
        dates_unknown: true,
        duration: 2
      }

      assert {:ok, %Trip{} = trip} = Planning.update_trip(trip, update_attrs)
      assert trip.name == "Venice on weekend maybe"
      assert trip.slug == "venice-on-weekend-maybe"
      assert trip.dates_unknown
      assert trip.duration == 2
      assert trip.start_date == nil
      assert trip.end_date == nil
    end

    test "update_trip/2 with invalid data returns error changeset" do
      trip = trip_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.update_trip(trip, %{name: nil})
      assert trip.name == Planning.get_trip!(trip.id).name
    end

    test "update_trip/2 validates that dates are required when status is finished" do
      trip = trip_fixture(%{status: Trip.finished()})

      assert {:error, %Ecto.Changeset{}} = Planning.update_trip(trip, %{dates_unknown: true})
      refute Planning.get_trip!(trip.id).dates_unknown
    end

    test "delete_trip/1 deletes the trip" do
      trip = trip_fixture()
      assert {:ok, %Trip{}} = Planning.delete_trip(trip)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_trip!(trip.id) end
    end

    test "change_trip/1 returns a trip changeset" do
      trip = trip_fixture()
      assert %Ecto.Changeset{} = Planning.change_trip(trip)
    end
  end
end
