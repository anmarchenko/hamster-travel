defmodule HamsterTravel.PlanningTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Planning
  alias HamsterTravel.Social

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures
  import HamsterTravel.GeoFixtures

  setup do
    user = user_fixture()
    friend = user_fixture()
    Social.add_friends(user.id, friend.id)
    geonames_fixture()
    berlin = HamsterTravel.Geo.find_city_by_geonames_id("2950159")

    {:ok,
     user: Repo.preload(user, :friendships),
     friend: Repo.preload(friend, :friendships),
     city: berlin}
  end

  describe "trips" do
    alias HamsterTravel.Planning.Trip

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

    test "list_plans/1 without user returns public trips with planned and finished statuses", %{
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

      %{id: _second_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.planned(),
          start_date: ~D[2023-03-01],
          end_date: ~D[2023-03-02],
          private: true
        })

      %{id: friend_id} = trip_fixture(%{author_id: friend.id, status: Trip.finished()})
      %{id: _draft_id} = trip_fixture(%{author_id: user.id, status: Trip.draft()})

      assert [
               %Trip{id: ^first_id},
               %Trip{id: ^friend_id}
             ] =
               Planning.list_plans()
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

    test "next_plans/1 returns nearest plans belonging to the user", %{
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

      %{id: _third_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.finished(),
          start_date: ~D[2023-03-01],
          end_date: ~D[2023-03-02]
        })

      %{id: _friend_id} = trip_fixture(%{author_id: friend.id, status: Trip.planned()})
      %{id: _draft_id} = trip_fixture(%{author_id: user.id, status: Trip.draft()})

      assert [
               %Trip{id: ^second_id},
               %Trip{id: ^first_id}
             ] =
               Planning.next_plans(user)
    end

    test "last_trips/1 returns most recent trips belonging to the user", %{
      user: user,
      friend: friend
    } do
      %{id: _first_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.planned(),
          start_date: ~D[2023-06-12],
          end_date: ~D[2023-06-13]
        })

      %{id: second_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.finished(),
          start_date: ~D[2023-03-01],
          end_date: ~D[2023-03-02]
        })

      %{id: third_id} =
        trip_fixture(%{
          author_id: user.id,
          status: Trip.finished(),
          start_date: ~D[2023-07-01],
          end_date: ~D[2023-07-02]
        })

      %{id: _friend_id} = trip_fixture(%{author_id: friend.id, status: Trip.finished()})
      %{id: _draft_id} = trip_fixture(%{author_id: user.id, status: Trip.draft()})

      assert [
               %Trip{id: ^third_id},
               %Trip{id: ^second_id}
             ] =
               Planning.last_trips(user)
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

    test "update_trip/2 adjusts destinations when trip duration is reduced", %{city: city} do
      # Create a trip with duration 5 days
      trip =
        trip_fixture(%{
          dates_unknown: true,
          duration: 5
        })

      # Create destinations spanning different days
      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 0,
          end_day: 2
        })

      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 3,
          end_day: 4
        })

      # Update trip to reduce duration to 3 days
      assert {:ok, updated_trip} = Planning.update_trip(trip, %{duration: 3})

      # Verify trip was updated
      assert updated_trip.duration == 3

      # Verify destinations were adjusted
      [updated_dest1, updated_dest2] =
        Planning.list_destinations(updated_trip) |> Enum.sort_by(& &1.start_day)

      assert updated_dest1.start_day == 0
      assert updated_dest1.end_day == 2
      assert updated_dest2.start_day == 3
      assert updated_dest2.end_day == 4
    end

    test "update_trip/2 does not adjust destinations when trip duration is increased", %{
      city: city
    } do
      # Create a trip with duration 3 days
      trip =
        trip_fixture(%{
          dates_unknown: true,
          duration: 3
        })

      # Create destinations
      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 0,
          end_day: 1
        })

      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 2,
          end_day: 2
        })

      # Update trip to increase duration to 5 days
      assert {:ok, updated_trip} = Planning.update_trip(trip, %{duration: 5})

      # Verify trip was updated
      assert updated_trip.duration == 5

      # Verify destinations were not adjusted
      [updated_dest1, updated_dest2] =
        Planning.list_destinations(updated_trip) |> Enum.sort_by(& &1.start_day)

      assert updated_dest1.start_day == 0
      assert updated_dest1.end_day == 1
      assert updated_dest2.start_day == 2
      assert updated_dest2.end_day == 2
    end

    test "update_trip/2 doesn't adjust destination if it falls outside the new duration", %{
      city: city
    } do
      # Create a trip with duration 7 days
      trip =
        trip_fixture(%{
          dates_unknown: true,
          duration: 7
        })

      # Create destinations spanning different days
      {:ok, _dest1} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 0,
          end_day: 2
        })

      {:ok, _dest2} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 3,
          end_day: 5
        })

      {:ok, _dest3} =
        Planning.create_destination(trip, %{
          city_id: city.id,
          start_day: 6,
          end_day: 6
        })

      # Update trip to reduce duration to 4 days
      assert {:ok, updated_trip} = Planning.update_trip(trip, %{duration: 4})

      # Verify trip was updated
      assert updated_trip.duration == 4

      # Verify destinations were adjusted
      [updated_dest1, updated_dest2, updated_dest3] =
        Planning.list_destinations(updated_trip) |> Enum.sort_by(& &1.start_day)

      assert updated_dest1.start_day == 0
      assert updated_dest1.end_day == 2
      assert updated_dest2.start_day == 3
      assert updated_dest2.end_day == 3
      assert updated_dest3.start_day == 6
      assert updated_dest3.end_day == 6
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

  describe "destinations" do
    alias HamsterTravel.Planning.Destination

    @invalid_attrs %{start_day: nil, end_day: nil}
    @update_attrs %{start_day: 43, end_day: 43}

    setup do
      geonames_fixture()
      berlin = HamsterTravel.Geo.find_city_by_geonames_id("2950159")
      trip = trip_fixture()

      {:ok, city: berlin, trip: trip}
    end

    test "list_destinations/1 returns all destinations for a trip" do
      destination = destination_fixture()
      [result] = Planning.list_destinations(destination.trip_id)
      assert result.id == destination.id
      assert result.city_id == destination.city_id
      assert result.trip_id == destination.trip_id
      assert result.start_day == destination.start_day
      assert result.end_day == destination.end_day
    end

    test "get_destination!/1 returns the destination with given id" do
      destination = destination_fixture()
      result = Planning.get_destination!(destination.id)
      assert result.id == destination.id
      assert result.city_id == destination.city_id
      assert result.trip_id == destination.trip_id
      assert result.start_day == destination.start_day
      assert result.end_day == destination.end_day
    end

    test "create_destination/1 with valid data creates a destination", %{city: city, trip: trip} do
      valid_attrs = %{
        city_id: city.id,
        start_day: 0,
        end_day: 1
      }

      assert {:ok, %Destination{} = destination} = Planning.create_destination(trip, valid_attrs)
      assert destination.city_id == city.id
      assert destination.start_day == 0
      assert destination.end_day == 1
      assert destination.trip_id == trip.id
    end

    test "create_destination/1 broadcasts destination creation", %{city: city, trip: trip} do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{trip.id}")

      valid_attrs = %{
        city_id: city.id,
        start_day: 0,
        end_day: 1
      }

      # Act
      {:ok, destination} = Planning.create_destination(trip, valid_attrs)

      # Assert
      assert_receive {[:destination, :created], %{value: ^destination}}
    end

    test "create_destination/1 with invalid data returns error changeset" do
      trip = trip_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.create_destination(trip, @invalid_attrs)
    end

    test "create_destination/1 fails if end_day is less than start_day", %{city: city} do
      trip = trip_fixture()

      invalid_attrs = %{
        start_day: 10,
        end_day: 5,
        city_id: city.id
      }

      assert {:error, %Ecto.Changeset{}} = Planning.create_destination(trip, invalid_attrs)
    end

    test "no negative start_day", %{city: city} do
      trip = trip_fixture()

      # Try to insert destination with negative start_day using Planning context
      attrs = %{start_day: -1, end_day: 0, city_id: city.id}

      assert {:error, %Ecto.Changeset{} = changeset} = Planning.create_destination(trip, attrs)
      assert %{start_day: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "no negative end_day", %{city: city} do
      trip = trip_fixture()

      # Try to insert destination with negative end_day using Planning context
      attrs = %{start_day: 0, end_day: -1, city_id: city.id}

      assert {:error, %Ecto.Changeset{} = changeset} = Planning.create_destination(trip, attrs)
      assert errors_on(changeset).end_day |> Enum.member?("must be greater than or equal to 0")
    end

    test "start_day must be less than end_day", %{city: city} do
      trip = trip_fixture()

      # Try to insert destination with start_day > end_day using Planning context
      attrs = %{start_day: 5, end_day: 3, city_id: city.id}

      assert {:error, %Ecto.Changeset{} = changeset} = Planning.create_destination(trip, attrs)
      assert %{end_day: ["must be greater than or equal to start_day"]} = errors_on(changeset)
    end

    test "update_destination/2 with valid data updates the destination" do
      destination = destination_fixture()

      assert {:ok, %Destination{} = updated_destination} =
               Planning.update_destination(destination, @update_attrs)

      assert updated_destination.start_day == 43
      assert updated_destination.end_day == 43
    end

    test "update_destination/2 sends pubsub event", %{trip: trip} do
      destination = destination_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{trip.id}")

      assert {:ok, %Destination{} = updated_destination} =
               Planning.update_destination(destination, @update_attrs)

      assert_receive {[:destination, :updated], %{value: ^updated_destination}}
    end

    test "update_destination/2 with invalid data returns error changeset" do
      destination = destination_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Planning.update_destination(destination, @invalid_attrs)

      result = Planning.get_destination!(destination.id)
      assert result.id == destination.id
      assert result.city_id == destination.city_id
      assert result.trip_id == destination.trip_id
      assert result.start_day == destination.start_day
      assert result.end_day == destination.end_day
    end

    test "delete_destination/1 deletes the destination" do
      destination = destination_fixture()
      assert {:ok, %Destination{}} = Planning.delete_destination(destination)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_destination!(destination.id) end
    end

    test "delete_destination/1 sends pubsub event", %{trip: trip} do
      destination = destination_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{trip.id}")

      assert {:ok, %Destination{} = deleted_destination} =
               Planning.delete_destination(destination)

      assert_receive {[:destination, :deleted], %{value: ^deleted_destination}}
    end

    test "change_destination/1 returns a destination changeset" do
      destination = destination_fixture()
      assert %Ecto.Changeset{} = Planning.change_destination(destination)
    end

    test "new_destination/2 returns a new destination changeset with trip_id, nil city, start_day and end_day are for the whole trip" do
      trip = trip_fixture() |> Repo.preload(:destinations)
      changeset = Planning.new_destination(trip, 0)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 city: nil,
                 start_day: 0,
                 end_day: 2
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "new_destination/2 when trip already has some destinations returns a new destination changeset start_day and end_day for the current day index" do
      trip = trip_fixture()
      destination_fixture(%{trip_id: trip.id, start_day: 0, end_day: 1})
      trip = trip |> Repo.preload(:destinations)
      changeset = Planning.new_destination(trip, 1)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 city: nil,
                 start_day: 1,
                 end_day: 1
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "new_destination/2 with attributes overrides default values" do
      trip = trip_fixture()
      attrs = %{start_day: 1, end_day: 2}
      changeset = Planning.new_destination(trip, 0, attrs)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 city: nil
               },
               changes: %{
                 start_day: 1,
                 end_day: 2
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "destinations_for_day/2 returns destinations active on the given day" do
      # Create destinations with different day ranges
      destination1 = destination_fixture(%{start_day: 1, end_day: 3})
      destination2 = destination_fixture(%{start_day: 2, end_day: 4})
      destination3 = destination_fixture(%{start_day: 4, end_day: 6})

      destinations = [destination1, destination2, destination3]

      # Test day 2 (should include destination1 and destination2)
      assert [^destination1, ^destination2] = Planning.destinations_for_day(2, destinations)

      # Test day 4 (should include destination2 and destination3)
      assert [^destination2, ^destination3] = Planning.destinations_for_day(4, destinations)

      # Test day 5 (should only include destination3)
      assert [^destination3] = Planning.destinations_for_day(5, destinations)

      # Test day 0 (should return empty list as no destinations start on day 0)
      assert [] = Planning.destinations_for_day(0, destinations)
    end

    test "destinations_for_day/2 handles single-day destinations" do
      destination = destination_fixture(%{start_day: 2, end_day: 2})

      assert [^destination] = Planning.destinations_for_day(2, [destination])
      assert [] = Planning.destinations_for_day(1, [destination])
      assert [] = Planning.destinations_for_day(3, [destination])
    end

    test "destinations_for_day/2 handles empty list of destinations" do
      assert [] = Planning.destinations_for_day(1, [])
    end
  end

  describe "trip associations" do
    alias HamsterTravel.Planning.Trip

    test "preloads countries through destinations and cities", %{user: user} do
      # Setup test data
      geonames_fixture()
      berlin = HamsterTravel.Geo.find_city_by_geonames_id("2950159")
      hamburg = HamsterTravel.Geo.find_city_by_geonames_id("2911298")

      # Create a trip with multiple destinations
      {:ok, trip} =
        Planning.create_trip(
          %{
            name: "German Tour",
            dates_unknown: false,
            start_date: ~D[2023-06-12],
            end_date: ~D[2023-06-14],
            currency: "EUR",
            status: Trip.planned(),
            private: false,
            people_count: 2
          },
          user
        )

      # Add destinations
      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: berlin.id,
          start_day: 0,
          end_day: 1
        })

      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: hamburg.id,
          start_day: 2,
          end_day: 2
        })

      # Fetch trip with preloaded associations
      trip =
        Planning.get_trip!(trip.id)
        |> Repo.preload([:cities])

      # Verify the associations
      assert length(trip.destinations) == 2
      assert length(trip.cities) == 2
      # Both cities are in Germany
      assert length(trip.countries) == 1

      # Verify we can access country data
      [country] = trip.countries
      assert country.iso == "DE"
    end

    test "preloads countries in list_plans", %{user: user} do
      # Setup test data
      geonames_fixture()
      berlin = HamsterTravel.Geo.find_city_by_geonames_id("2950159")

      # Create a trip
      {:ok, trip} =
        Planning.create_trip(
          %{
            name: "Berlin Trip",
            dates_unknown: false,
            start_date: ~D[2023-06-12],
            end_date: ~D[2023-06-13],
            currency: "EUR",
            status: Trip.planned(),
            private: false,
            people_count: 2
          },
          user
        )

      # Add destination
      {:ok, _} =
        Planning.create_destination(trip, %{
          city_id: berlin.id,
          start_day: 0,
          end_day: 1
        })

      # Fetch trips with preloaded associations
      [loaded_trip] =
        Planning.list_plans(user)
        |> Repo.preload([:cities])

      # Verify the associations
      assert length(loaded_trip.destinations) == 1
      assert length(loaded_trip.cities) == 1
      assert length(loaded_trip.countries) == 1

      # Verify country data
      [country] = loaded_trip.countries
      assert country.iso == "DE"
    end
  end

  describe "expenses" do
    alias HamsterTravel.Planning.Expense

    test "list_expenses/1 returns all expenses for a trip" do
      trip = trip_fixture()
      expense1 = expense_fixture(%{trip_id: trip.id, name: "Hotel"})
      expense2 = expense_fixture(%{trip_id: trip.id, name: "Food"})
      _other_expense = expense_fixture()

      expenses = Planning.list_expenses(trip)
      expense_ids = Enum.map(expenses, & &1.id)

      assert length(expenses) == 2
      assert expense1.id in expense_ids
      assert expense2.id in expense_ids
    end

    test "get_expense!/1 returns the expense with given id" do
      expense = expense_fixture()
      assert Planning.get_expense!(expense.id).id == expense.id
    end

    test "create_expense/2 with valid data creates an expense" do
      trip = trip_fixture()
      valid_attrs = %{price: Money.new(:EUR, 2500), name: "Restaurant"}

      assert {:ok, %Expense{} = expense} = Planning.create_expense(trip, valid_attrs)
      assert expense.price == Money.new(:EUR, 2500)
      assert expense.name == "Restaurant"
      assert expense.trip_id == trip.id
    end

    test "create_expense/2 with invalid data returns error changeset" do
      trip = trip_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.create_expense(trip, %{})
    end

    test "update_expense/2 with valid data updates the expense" do
      expense = expense_fixture()
      update_attrs = %{price: Money.new(:USD, 3000), name: "Updated expense"}

      assert {:ok, %Expense{} = expense} = Planning.update_expense(expense, update_attrs)
      assert expense.price == Money.new(:USD, 3000)
      assert expense.name == "Updated expense"
    end

    test "update_expense/2 with invalid data returns error changeset" do
      expense = expense_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.update_expense(expense, %{price: nil})
      assert expense == Planning.get_expense!(expense.id)
    end

    test "delete_expense/1 deletes the expense" do
      expense = expense_fixture()
      assert {:ok, %Expense{}} = Planning.delete_expense(expense)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_expense!(expense.id) end
    end

    test "change_expense/1 returns an expense changeset" do
      expense = expense_fixture()
      assert %Ecto.Changeset{} = Planning.change_expense(expense)
    end

    test "new_expense/1 returns a new expense changeset with trip_id" do
      trip = trip_fixture()
      changeset = Planning.new_expense(trip)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "create_expense/2 broadcasts pubsub event" do
      trip = trip_fixture()
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{trip.id}")

      assert {:ok, %Expense{} = expense} =
               Planning.create_expense(trip, %{price: Money.new(:EUR, 1000), name: "Test"})

      assert_receive {[:expense, :created], %{value: ^expense}}
    end

    test "update_expense/2 broadcasts pubsub event" do
      expense = expense_fixture()
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{expense.trip_id}")

      assert {:ok, %Expense{} = updated_expense} =
               Planning.update_expense(expense, %{name: "Updated"})

      assert_receive {[:expense, :updated], %{value: ^updated_expense}}
    end

    test "delete_expense/1 broadcasts pubsub event" do
      expense = expense_fixture()
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{expense.trip_id}")

      assert {:ok, %Expense{} = deleted_expense} = Planning.delete_expense(expense)

      assert_receive {[:expense, :deleted], %{value: ^deleted_expense}}
    end
  end
end
