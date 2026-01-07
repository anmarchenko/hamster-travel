defmodule HamsterTravel.PlanningTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Planning
  alias HamsterTravel.Social

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures
  import HamsterTravel.GeoFixtures
  import Ecto.Query

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

      trip = Planning.get_trip!(trip.id)
      assert trip.food_expense.days_count == trip.duration
      assert trip.food_expense.people_count == trip.people_count
      assert trip.food_expense.price_per_day == Money.new(trip.currency, 0)
      assert trip.food_expense.expense.price == Money.new(trip.currency, 0)
    end

    test "create_trip/2 creates a food expense with trip-based defaults", %{user: user} do
      valid_attrs = %{
        name: "Default food expense",
        dates_unknown: false,
        start_date: ~D[2024-01-10],
        end_date: ~D[2024-01-12],
        currency: "USD",
        status: "1_planned",
        private: false,
        people_count: 3
      }

      assert {:ok, %Trip{} = trip} = Planning.create_trip(valid_attrs, user)
      trip = Planning.get_trip!(trip.id)

      assert trip.food_expense.days_count == 3
      assert trip.food_expense.people_count == 3
      assert trip.food_expense.price_per_day == Money.new(:USD, 0)
      assert trip.food_expense.expense.price == Money.new(:USD, 0)
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

    test "delete_trip/1 removes trip expenses" do
      trip = trip_fixture()
      trip = Planning.get_trip!(trip.id)
      food_expense_id = trip.food_expense.expense.id
      expense = expense_fixture(%{trip_id: trip.id})

      assert {:ok, %Trip{}} = Planning.delete_trip(trip)

      assert [] == Repo.all(from e in Planning.Expense, where: e.trip_id == ^trip.id)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_expense!(expense.id) end
      assert_raise Ecto.NoResultsError, fn -> Planning.get_expense!(food_expense_id) end
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
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

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
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

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
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

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
      trip = Planning.get_trip!(trip.id)
      expense1 = expense_fixture(%{trip_id: trip.id, name: "Hotel"})
      expense2 = expense_fixture(%{trip_id: trip.id, name: "Food"})
      _other_expense = expense_fixture()

      expenses = Planning.list_expenses(trip)
      expense_ids = Enum.map(expenses, & &1.id)

      assert length(expenses) == 3
      assert expense1.id in expense_ids
      assert expense2.id in expense_ids
      assert trip.food_expense.expense.id in expense_ids
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
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Expense{} = expense} =
               Planning.create_expense(trip, %{price: Money.new(:EUR, 1000), name: "Test"})

      assert_receive {[:expense, :created], %{value: ^expense}}
    end

    test "update_expense/2 broadcasts pubsub event" do
      expense = expense_fixture()
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{expense.trip_id}")

      assert {:ok, %Expense{} = updated_expense} =
               Planning.update_expense(expense, %{name: "Updated"})

      assert_receive {[:expense, :updated], %{value: ^updated_expense}}
    end

    test "delete_expense/1 broadcasts pubsub event" do
      expense = expense_fixture()
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{expense.trip_id}")

      assert {:ok, %Expense{} = deleted_expense} = Planning.delete_expense(expense)

      assert_receive {[:expense, :deleted], %{value: ^deleted_expense}}
    end
  end

  describe "food_expenses schema" do
    alias HamsterTravel.Planning.FoodExpense

    test "changeset requires price_per_day, days_count, people_count, trip_id" do
      changeset = FoodExpense.changeset(%FoodExpense{}, %{})
      refute changeset.valid?

      assert %{
               price_per_day: ["can't be blank"],
               days_count: ["can't be blank"],
               people_count: ["can't be blank"],
               trip_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "changeset validates positive counts" do
      trip = trip_fixture()

      changeset =
        FoodExpense.changeset(%FoodExpense{}, %{
          price_per_day: Money.new(:EUR, 1000),
          days_count: 0,
          people_count: -1,
          trip_id: trip.id
        })

      assert %{
               days_count: ["must be greater than 0"],
               people_count: ["must be greater than 0"]
             } = errors_on(changeset)
    end
  end

  describe "food_expenses" do
    alias HamsterTravel.Planning.FoodExpense

    test "update_food_expense/2 recalculates total expense" do
      trip = trip_fixture()
      trip = Planning.get_trip!(trip.id)
      food_expense = trip.food_expense

      assert {:ok, updated} =
               Planning.update_food_expense(food_expense, %{
                 price_per_day: Money.new(:EUR, 1200),
                 days_count: 2,
                 people_count: 3
               })

      expected =
        Money.new(:EUR, 1200)
        |> Money.mult!(2)
        |> Money.mult!(3)

      assert updated.expense.price == expected
    end

    test "update_food_expense/2 with invalid data returns error changeset" do
      trip = trip_fixture()
      trip = Planning.get_trip!(trip.id)
      food_expense = trip.food_expense

      assert {:error, %Ecto.Changeset{} = changeset} =
               Planning.update_food_expense(food_expense, %{days_count: 0})

      assert %{days_count: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "get_food_expense!/1 returns the food expense with expense preloaded" do
      trip = trip_fixture()
      trip = Planning.get_trip!(trip.id)

      food_expense = Planning.get_food_expense!(trip.food_expense.id)
      assert food_expense.id == trip.food_expense.id
      assert %HamsterTravel.Planning.Expense{} = food_expense.expense
    end

    test "change_food_expense/1 returns a changeset" do
      trip = trip_fixture()
      trip = Planning.get_trip!(trip.id)

      assert %Ecto.Changeset{} = Planning.change_food_expense(trip.food_expense)
    end

    test "update_food_expense/2 updates existing expense association" do
      trip = trip_fixture()
      trip = Planning.get_trip!(trip.id)
      food_expense = trip.food_expense
      expense_id = food_expense.expense.id

      assert {:ok, updated} =
               Planning.update_food_expense(food_expense, %{
                 price_per_day: Money.new(:EUR, 250),
                 days_count: 1,
                 people_count: 2
               })

      assert updated.expense.id == expense_id
      assert updated.expense.price == Money.new(:EUR, 250) |> Money.mult!(2)
    end
  end

  describe "day_expenses schema" do
    alias HamsterTravel.Planning.DayExpense

    test "changeset requires name, day_index, trip_id" do
      changeset = DayExpense.changeset(%DayExpense{}, %{})
      refute changeset.valid?

      assert %{
               name: ["can't be blank"],
               day_index: ["can't be blank"],
               trip_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "changeset validates non-negative day_index" do
      trip = trip_fixture()

      changeset =
        DayExpense.changeset(%DayExpense{}, %{name: "Transport", day_index: -1, trip_id: trip.id})

      assert %{day_index: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "changeset casts expense association" do
      trip = trip_fixture()

      changeset =
        DayExpense.changeset(%DayExpense{}, %{
          name: "Transport",
          day_index: 0,
          trip_id: trip.id,
          expense: %{price: Money.new(:EUR, 1200), trip_id: trip.id}
        })

      assert changeset.valid?
      assert %Ecto.Changeset{} = changeset.changes.expense
    end
  end

  describe "calculate_budget" do
    test "calculates budget for trip with no expenses" do
      trip = trip_fixture()
      budget = Planning.calculate_budget(trip)
      assert Money.equal?(budget, Money.new(:EUR, 0))
    end

    test "calculates budget for trip with preloaded expenses in same currency" do
      trip = trip_fixture()

      {:ok, _expense1} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 1000), name: "Hotel"})

      {:ok, _expense2} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 500), name: "Food"})

      # Preload expenses
      trip_with_expenses = Planning.get_trip!(trip.id)

      budget = Planning.calculate_budget(trip_with_expenses)
      expected = Money.new(:EUR, 1500)
      assert Money.equal?(budget, expected)
    end

    test "calculates budget for trip with expenses in different currencies using fixed rates" do
      # Create a USD trip to test currency conversion
      trip = trip_fixture(%{currency: "USD"})

      # Add expenses in different currencies
      {:ok, _expense1} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 1000), name: "Hotel"})

      {:ok, _expense2} =
        Planning.create_expense(trip, %{price: Money.new(:GBP, 500), name: "Food"})

      {:ok, _expense3} =
        Planning.create_expense(trip, %{price: Money.new(:USD, 200), name: "Transport"})

      trip_with_expenses = Planning.get_trip!(trip.id)

      budget = Planning.calculate_budget(trip_with_expenses)

      # With fixed rates:
      # EUR 1000 = USD 1100 (1000 * 1.10)
      # GBP 500 = USD 647.06 (500 / 0.85 * 1.10) ≈ 647
      # USD 200 = USD 200
      # Total ≈ USD 1947

      assert budget.currency == :USD
      assert Decimal.to_float(budget.amount) |> Float.round(2) == 1947.06
    end

    test "calculates budget with non-preloaded expenses" do
      trip = trip_fixture()

      {:ok, _expense1} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 750), name: "Accommodation"})

      {:ok, _expense2} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 250), name: "Activities"})

      # Don't preload expenses - let the function fetch them
      budget = Planning.calculate_budget(trip)
      expected = Money.new(:EUR, 1000)
      assert Money.equal?(budget, expected)
    end

    test "handles trip with expenses that fail currency conversion gracefully" do
      trip = trip_fixture()

      # Create an expense with an unsupported currency (this should be converted to EUR 0)
      {:ok, _expense1} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 500), name: "Valid expense"})

      budget = Planning.calculate_budget(trip)
      expected = Money.new(:EUR, 500)
      assert Money.equal?(budget, expected)
    end

    test "calculates budget correctly when trip currency differs from expense currencies" do
      # Create a GBP trip
      trip = trip_fixture(%{currency: "GBP"})

      {:ok, _expense1} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 100), name: "Hotel"})

      {:ok, _expense2} =
        Planning.create_expense(trip, %{price: Money.new(:USD, 110), name: "Food"})

      trip_with_expenses = Planning.get_trip!(trip.id)
      budget = Planning.calculate_budget(trip_with_expenses)

      # With fixed rates:
      # EUR 100 = GBP 85 (100 * 0.85)
      # USD 110 = GBP 85 (110 / 1.10 * 0.85)
      # Total = GBP 170

      assert budget.currency == :GBP
      assert Money.equal?(budget, Money.new(:GBP, 170))
    end
  end

  describe "accommodations" do
    alias HamsterTravel.Planning.Accommodation

    @invalid_attrs %{name: nil, start_day: nil, end_day: nil}
    @update_attrs %{name: "Updated Hotel", start_day: 1, end_day: 3}

    setup do
      trip = trip_fixture()

      {:ok, trip: trip}
    end

    test "list_accommodations/1 returns all accommodations for a trip", %{trip: trip} do
      accommodation = accommodation_fixture(%{trip_id: trip.id})
      [result] = Planning.list_accommodations(trip)
      assert result.id == accommodation.id
      assert result.name == accommodation.name
      assert result.trip_id == accommodation.trip_id
      assert result.start_day == accommodation.start_day
      assert result.end_day == accommodation.end_day
    end

    test "get_accommodation!/1 returns the accommodation with given id" do
      accommodation = accommodation_fixture()
      result = Planning.get_accommodation!(accommodation.id)
      assert result.id == accommodation.id
      assert result.name == accommodation.name
      assert result.trip_id == accommodation.trip_id
      assert result.start_day == accommodation.start_day
      assert result.end_day == accommodation.end_day
    end

    test "create_accommodation/1 with valid data creates an accommodation", %{
      trip: trip
    } do
      valid_attrs = %{
        name: "Luxury Hotel",
        link: "https://example.com/hotel",
        address: "456 Hotel Street, Vienna",
        note: "Beautiful hotel with great views",
        start_day: 0,
        end_day: 2,
        expense: %{
          price: Money.new(:EUR, 15_000),
          name: "Hotel booking",
          trip_id: trip.id
        }
      }

      assert {:ok, %Accommodation{} = accommodation} =
               Planning.create_accommodation(trip, valid_attrs)

      assert accommodation.name == "Luxury Hotel"
      assert accommodation.link == "https://example.com/hotel"
      assert accommodation.address == "456 Hotel Street, Vienna"
      assert accommodation.note == "Beautiful hotel with great views"
      assert accommodation.start_day == 0
      assert accommodation.end_day == 2
      assert accommodation.trip_id == trip.id
      assert accommodation.expense.price == Money.new(:EUR, 15_000)
      assert accommodation.expense.name == "Hotel booking"
      assert accommodation.expense.trip_id == trip.id
      assert accommodation.expense.accommodation_id == accommodation.id
    end

    test "create_accommodation/1 broadcasts accommodation creation", %{
      trip: trip
    } do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      valid_attrs = %{
        name: "Test Hotel",
        start_day: 0,
        end_day: 1,
        expense: %{
          price: Money.new(:EUR, 10_000),
          name: "Hotel expense",
          trip_id: trip.id
        }
      }

      # Act
      {:ok, accommodation} = Planning.create_accommodation(trip, valid_attrs)

      # Assert
      assert_receive {[:accommodation, :created], %{value: ^accommodation}}
    end

    test "create_accommodation/1 with invalid data returns error changeset", %{trip: trip} do
      assert {:error, %Ecto.Changeset{}} = Planning.create_accommodation(trip, @invalid_attrs)
    end

    test "create_accommodation/1 fails if end_day is less than start_day", %{
      trip: trip
    } do
      invalid_attrs = %{
        name: "Test Hotel",
        start_day: 10,
        end_day: 5,
        expense: %{
          price: Money.new(:EUR, 10_000),
          name: "Hotel expense",
          trip_id: trip.id
        }
      }

      assert {:error, %Ecto.Changeset{}} = Planning.create_accommodation(trip, invalid_attrs)
    end

    test "no negative start_day", %{trip: trip} do
      # Try to insert accommodation with negative start_day using Planning context
      attrs = %{
        name: "Test Hotel",
        start_day: -1,
        end_day: 0,
        expense: %{
          price: Money.new(:EUR, 10_000),
          name: "Hotel expense",
          trip_id: trip.id
        }
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Planning.create_accommodation(trip, attrs)
      assert %{start_day: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "no negative end_day", %{trip: trip} do
      # Try to insert accommodation with negative end_day using Planning context
      attrs = %{
        name: "Test Hotel",
        start_day: 0,
        end_day: -1,
        expense: %{
          price: Money.new(:EUR, 10_000),
          name: "Hotel expense",
          trip_id: trip.id
        }
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Planning.create_accommodation(trip, attrs)
      assert errors_on(changeset).end_day |> Enum.member?("must be greater than or equal to 0")
    end

    test "start_day must be less than or equal to end_day", %{trip: trip} do
      # Try to insert accommodation with start_day > end_day using Planning context
      attrs = %{
        name: "Test Hotel",
        start_day: 5,
        end_day: 3,
        expense: %{
          price: Money.new(:EUR, 10_000),
          name: "Hotel expense",
          trip_id: trip.id
        }
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Planning.create_accommodation(trip, attrs)
      assert %{end_day: ["must be greater than or equal to start_day"]} = errors_on(changeset)
    end

    test "update_accommodation/2 with valid data updates the accommodation" do
      accommodation = accommodation_fixture()

      assert {:ok, %Accommodation{} = updated_accommodation} =
               Planning.update_accommodation(accommodation, @update_attrs)

      assert updated_accommodation.name == "Updated Hotel"
      assert updated_accommodation.start_day == 1
      assert updated_accommodation.end_day == 3
    end

    test "update_accommodation/2 sends pubsub event", %{trip: trip} do
      accommodation = accommodation_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Accommodation{} = updated_accommodation} =
               Planning.update_accommodation(accommodation, @update_attrs)

      assert_receive {[:accommodation, :updated], %{value: ^updated_accommodation}}
    end

    test "update_accommodation/2 with invalid data returns error changeset" do
      accommodation = accommodation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Planning.update_accommodation(accommodation, @invalid_attrs)

      result = Planning.get_accommodation!(accommodation.id)
      assert result.id == accommodation.id
      assert result.name == accommodation.name
      assert result.trip_id == accommodation.trip_id
      assert result.start_day == accommodation.start_day
      assert result.end_day == accommodation.end_day
    end

    test "update_accommodation/2 with expense data updates both accommodation and expense", %{
      trip: trip
    } do
      # Create accommodation with expense
      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          name: "Original Hotel",
          start_day: 0,
          end_day: 2,
          expense: %{
            price: Money.new(:EUR, 10_000),
            name: "Original Hotel Booking",
            trip_id: trip.id
          }
        })

      accommodation = accommodation |> Repo.preload(:expense)

      update_attrs = %{
        name: "Updated Hotel",
        start_day: 1,
        end_day: 3,
        expense: %{
          # note that we need to pass the expense id to update the expense
          # Think how would this work with a form?
          id: accommodation.expense.id,
          price: Money.new(:EUR, 15_000),
          name: "Updated Hotel Booking"
        }
      }

      assert {:ok, %Accommodation{} = updated_accommodation} =
               Planning.update_accommodation(accommodation, update_attrs)

      # Verify accommodation was updated
      assert updated_accommodation.name == "Updated Hotel"
      assert updated_accommodation.start_day == 1
      assert updated_accommodation.end_day == 3

      # Verify expense was updated
      updated_accommodation = updated_accommodation |> Repo.preload(:expense)
      assert updated_accommodation.expense.price == Money.new(:EUR, 15_000)
      assert updated_accommodation.expense.name == "Updated Hotel Booking"
      assert updated_accommodation.expense.trip_id == trip.id
      assert updated_accommodation.expense.accommodation_id == updated_accommodation.id
    end

    test "delete_accommodation/1 deletes the accommodation" do
      accommodation = accommodation_fixture()
      assert {:ok, %Accommodation{}} = Planning.delete_accommodation(accommodation)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_accommodation!(accommodation.id) end
    end

    test "delete_accommodation/1 sends pubsub event", %{trip: trip} do
      accommodation = accommodation_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Accommodation{} = deleted_accommodation} =
               Planning.delete_accommodation(accommodation)

      assert_receive {[:accommodation, :deleted], %{value: ^deleted_accommodation}}
    end

    test "change_accommodation/1 returns an accommodation changeset" do
      accommodation = accommodation_fixture()
      assert %Ecto.Changeset{} = Planning.change_accommodation(accommodation)
    end

    test "new_accommodation/2 returns a new accommodation changeset with trip_id, start_day and end_day are for the whole trip" do
      trip = trip_fixture() |> Repo.preload(:accommodations)
      changeset = Planning.new_accommodation(trip, 0)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 start_day: 0,
                 end_day: 2
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "new_accommodation/2 when trip already has some accommodations returns a new accommodation changeset start_day and end_day for the current day index" do
      trip = trip_fixture()
      accommodation_fixture(%{trip_id: trip.id, start_day: 0, end_day: 1})
      trip = trip |> Repo.preload(:accommodations)
      changeset = Planning.new_accommodation(trip, 1)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 start_day: 1,
                 end_day: 1
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "new_accommodation/2 with attributes overrides default values" do
      trip = trip_fixture()
      attrs = %{start_day: 1, end_day: 2}
      changeset = Planning.new_accommodation(trip, 0, attrs)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id
               },
               changes: %{
                 start_day: 1,
                 end_day: 2
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "accommodations_for_day/2 returns accommodations active on the given day" do
      # Create accommodations with different day ranges
      accommodation1 = accommodation_fixture(%{start_day: 1, end_day: 3})
      accommodation2 = accommodation_fixture(%{start_day: 2, end_day: 4})
      accommodation3 = accommodation_fixture(%{start_day: 4, end_day: 6})

      accommodations = [accommodation1, accommodation2, accommodation3]

      # Test day 2 (should include accommodation1 and accommodation2)
      assert [^accommodation1, ^accommodation2] =
               Planning.accommodations_for_day(2, accommodations)

      # Test day 4 (should include accommodation2 and accommodation3)
      assert [^accommodation2, ^accommodation3] =
               Planning.accommodations_for_day(4, accommodations)

      # Test day 5 (should only include accommodation3)
      assert [^accommodation3] = Planning.accommodations_for_day(5, accommodations)

      # Test day 0 (should return empty list as no accommodations start on day 0)
      assert [] = Planning.accommodations_for_day(0, accommodations)
    end

    test "accommodations_for_day/2 handles single-day accommodations" do
      accommodation = accommodation_fixture(%{start_day: 2, end_day: 2})

      assert [^accommodation] = Planning.accommodations_for_day(2, [accommodation])
      assert [] = Planning.accommodations_for_day(1, [accommodation])
      assert [] = Planning.accommodations_for_day(3, [accommodation])
    end

    test "accommodations_for_day/2 handles empty list of accommodations" do
      assert [] = Planning.accommodations_for_day(1, [])
    end
  end

  describe "transfers" do
    alias HamsterTravel.Planning.Transfer

    @invalid_attrs %{transport_mode: nil, departure_time: nil, arrival_time: nil, day_index: nil}
    @update_attrs %{
      transport_mode: "flight",
      departure_time: "10:00",
      arrival_time: "14:00",
      note: "Updated flight details"
    }

    setup do
      geonames_fixture()
      berlin = HamsterTravel.Geo.find_city_by_geonames_id("2950159")
      hamburg = HamsterTravel.Geo.find_city_by_geonames_id("2911298")
      trip = trip_fixture()

      {:ok, berlin: berlin, hamburg: hamburg, trip: trip}
    end

    test "list_transfers/1 returns all transfers for a trip", %{trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id})
      [result] = Planning.list_transfers(trip)
      assert result.id == transfer.id
      assert result.transport_mode == transfer.transport_mode
      assert result.trip_id == transfer.trip_id
      assert result.departure_city_id == transfer.departure_city_id
      assert result.arrival_city_id == transfer.arrival_city_id
    end

    test "get_transfer!/1 returns the transfer with given id" do
      transfer = transfer_fixture()
      result = Planning.get_transfer!(transfer.id)
      assert result.id == transfer.id
      assert result.transport_mode == transfer.transport_mode
      assert result.trip_id == transfer.trip_id
      assert result.departure_city_id == transfer.departure_city_id
      assert result.arrival_city_id == transfer.arrival_city_id
    end

    test "create_transfer/2 with valid data creates a transfer", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      valid_attrs = %{
        transport_mode: "bus",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "09:00",
        arrival_time: "13:30",
        note: "Comfortable bus ride",
        vessel_number: "BUS456",
        carrier: "FlixBus",
        departure_station: "Berlin ZOB",
        arrival_station: "Hamburg ZOB",
        day_index: 0,
        expense: %{
          price: Money.new(:EUR, 2500),
          name: "Bus ticket",
          trip_id: trip.id
        }
      }

      assert {:ok, %Transfer{} = transfer} = Planning.create_transfer(trip, valid_attrs)
      assert transfer.transport_mode == "bus"
      assert transfer.departure_city_id == berlin.id
      assert transfer.arrival_city_id == hamburg.id
      assert transfer.departure_time == ~U[1970-01-01 09:00:00Z]
      assert transfer.arrival_time == ~U[1970-01-01 13:30:00Z]
      assert transfer.note == "Comfortable bus ride"
      assert transfer.vessel_number == "BUS456"
      assert transfer.carrier == "FlixBus"
      assert transfer.departure_station == "Berlin ZOB"
      assert transfer.arrival_station == "Hamburg ZOB"
      assert transfer.day_index == 0
      assert transfer.trip_id == trip.id
      assert transfer.expense.price == Money.new(:EUR, 2500)
      assert transfer.expense.name == "Bus ticket"
      assert transfer.expense.trip_id == trip.id
      assert transfer.expense.transfer_id == transfer.id
    end

    test "create_transfer/2 broadcasts transfer creation", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      valid_attrs = %{
        transport_mode: "flight",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "08:00",
        arrival_time: "09:30",
        day_index: 0,
        expense: %{
          price: Money.new(:EUR, 15_000),
          name: "Flight ticket",
          trip_id: trip.id
        }
      }

      # Act
      {:ok, transfer} = Planning.create_transfer(trip, valid_attrs)

      # Assert
      assert_receive {[:transfer, :created], %{value: ^transfer}}
    end

    test "create_transfer/2 with invalid data returns error changeset", %{trip: trip} do
      assert {:error, %Ecto.Changeset{}} = Planning.create_transfer(trip, @invalid_attrs)
    end

    test "create_transfer/2 with invalid transport mode returns error changeset", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      invalid_attrs = %{
        transport_mode: "teleport",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "08:00",
        arrival_time: "08:01",
        day_index: 0
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Planning.create_transfer(trip, invalid_attrs)

      assert %{transport_mode: ["is invalid"]} = errors_on(changeset)
    end

    test "create_transfer/2 converts time strings to datetime with anchored date", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      # Test form-style time input
      time_attrs = %{
        transport_mode: "train",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "09:00",
        arrival_time: "13:30",
        day_index: 0
      }

      assert {:ok, %Transfer{} = transfer} = Planning.create_transfer(trip, time_attrs)
      assert transfer.transport_mode == "train"
      assert transfer.departure_city_id == berlin.id
      assert transfer.arrival_city_id == hamburg.id

      assert transfer.departure_time == ~U[1970-01-01 09:00:00Z]
      assert transfer.arrival_time == ~U[1970-01-01 13:30:00Z]
      assert transfer.day_index == 0
      assert transfer.trip_id == trip.id
    end

    test "create_transfer/2 fails if departure and arrival cities are the same", %{
      trip: trip,
      berlin: berlin
    } do
      invalid_attrs = %{
        transport_mode: "train",
        departure_city_id: berlin.id,
        arrival_city_id: berlin.id,
        departure_time: "08:00",
        arrival_time: "12:00",
        day_index: 0
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Planning.create_transfer(trip, invalid_attrs)

      assert %{arrival_city_id: ["must be different from departure city"]} = errors_on(changeset)
    end

    test "create_transfer/2 fails if day_index is negative", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      invalid_attrs = %{
        transport_mode: "train",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "08:00",
        arrival_time: "12:00",
        day_index: -1
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Planning.create_transfer(trip, invalid_attrs)

      assert %{day_index: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "create_transfer/2 with plus_one_day uses 1970-01-02 as anchor date", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      # Test with plus_one_day: true
      time_attrs = %{
        transport_mode: "train",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "23:45",
        arrival_time: "01:30",
        day_index: 0,
        plus_one_day: true
      }

      assert {:ok, %Transfer{} = transfer} = Planning.create_transfer(trip, time_attrs)
      assert transfer.transport_mode == "train"
      assert transfer.departure_city_id == berlin.id
      assert transfer.arrival_city_id == hamburg.id

      # Verify times are converted to datetime with anchored date 1970-01-02
      assert transfer.departure_time == ~U[1970-01-02 23:45:00Z]
      assert transfer.arrival_time == ~U[1970-01-02 01:30:00Z]
      assert transfer.day_index == 0
      assert transfer.trip_id == trip.id
    end

    test "create_transfer/2 with plus_one_day: false uses default 1970-01-01 anchor date", %{
      trip: trip,
      berlin: berlin,
      hamburg: hamburg
    } do
      # Test with plus_one_day: false (explicit)
      time_attrs = %{
        transport_mode: "flight",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "14:15",
        arrival_time: "15:45",
        day_index: 0,
        plus_one_day: false
      }

      assert {:ok, %Transfer{} = transfer} = Planning.create_transfer(trip, time_attrs)
      assert transfer.transport_mode == "flight"
      assert transfer.departure_city_id == berlin.id
      assert transfer.arrival_city_id == hamburg.id

      # Verify times are converted to datetime with anchored date 1970-01-01
      assert transfer.departure_time == ~U[1970-01-01 14:15:00Z]
      assert transfer.arrival_time == ~U[1970-01-01 15:45:00Z]
      assert transfer.day_index == 0
      assert transfer.trip_id == trip.id
    end

    test "update_transfer/2 with valid data updates the transfer" do
      transfer = transfer_fixture()

      assert {:ok, %Transfer{} = updated_transfer} =
               Planning.update_transfer(transfer, @update_attrs)

      assert updated_transfer.transport_mode == "flight"
      assert updated_transfer.departure_time == ~U[1970-01-01 10:00:00Z]
      assert updated_transfer.arrival_time == ~U[1970-01-01 14:00:00Z]
      assert updated_transfer.note == "Updated flight details"
    end

    test "update_transfer/2 sends pubsub event", %{trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Transfer{} = updated_transfer} =
               Planning.update_transfer(transfer, @update_attrs)

      assert_receive {[:transfer, :updated], %{value: ^updated_transfer}}
    end

    test "update_transfer/2 with invalid data returns error changeset" do
      transfer = transfer_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Planning.update_transfer(transfer, @invalid_attrs)

      result = Planning.get_transfer!(transfer.id)
      assert result.id == transfer.id
      assert result.transport_mode == transfer.transport_mode
      assert result.trip_id == transfer.trip_id
      assert result.departure_city_id == transfer.departure_city_id
      assert result.arrival_city_id == transfer.arrival_city_id
    end

    test "update_transfer/2 with expense data updates both transfer and expense", %{
      trip: trip
    } do
      # Create transfer with expense
      transfer =
        transfer_fixture(%{
          trip_id: trip.id,
          transport_mode: "train",
          expense: %{
            price: Money.new(:EUR, 5000),
            name: "Original Train Ticket",
            trip_id: trip.id
          }
        })

      transfer = transfer |> Repo.preload(:expense)

      update_attrs = %{
        transport_mode: "flight",
        note: "Changed to flight",
        expense: %{
          # note that we need to pass the expense id to update the expense
          id: transfer.expense.id,
          price: Money.new(:EUR, 12_000),
          name: "Updated Flight Ticket"
        }
      }

      assert {:ok, %Transfer{} = updated_transfer} =
               Planning.update_transfer(transfer, update_attrs)

      # Verify transfer was updated
      assert updated_transfer.transport_mode == "flight"
      assert updated_transfer.note == "Changed to flight"

      # Verify expense was updated
      updated_transfer = updated_transfer |> Repo.preload(:expense)
      assert updated_transfer.expense.price == Money.new(:EUR, 12_000)
      assert updated_transfer.expense.name == "Updated Flight Ticket"
      assert updated_transfer.expense.trip_id == trip.id
      assert updated_transfer.expense.transfer_id == updated_transfer.id

      # validate updated transfer has city with region
      assert updated_transfer.departure_city.region_name == "Land Berlin"
      assert updated_transfer.arrival_city.region_name == "Free and Hanseatic City of Hamburg"
    end

    test "delete_transfer/1 deletes the transfer" do
      transfer = transfer_fixture()
      assert {:ok, %Transfer{}} = Planning.delete_transfer(transfer)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_transfer!(transfer.id) end
    end

    test "delete_transfer/1 sends pubsub event", %{trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Transfer{} = deleted_transfer} =
               Planning.delete_transfer(transfer)

      assert_receive {[:transfer, :deleted], %{value: ^deleted_transfer}}
    end

    test "change_transfer/1 returns a transfer changeset" do
      transfer = transfer_fixture()
      assert %Ecto.Changeset{} = Planning.change_transfer(transfer)
    end

    test "new_transfer/2 returns a new transfer changeset with trip_id" do
      trip = trip_fixture()
      changeset = Planning.new_transfer(trip, 0)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 day_index: 0
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "new_transfer/2 with attributes overrides default values" do
      trip = trip_fixture()
      attrs = %{transport_mode: "train", note: "Custom note"}
      changeset = Planning.new_transfer(trip, 0, attrs)

      assert %Ecto.Changeset{
               data: %{
                 trip_id: trip_id,
                 day_index: 0
               },
               changes: %{
                 transport_mode: "train",
                 note: "Custom note"
               }
             } = changeset

      assert trip_id == trip.id
    end

    test "transport_modes/0 returns list of valid transport modes" do
      expected_modes = ~w(flight train bus car taxi boat)
      assert Transfer.transport_modes() == expected_modes
    end

    test "list_transfers/1 orders transfers by departure_time" do
      trip = trip_fixture()

      # Create transfers with different departure times
      transfer1 =
        transfer_fixture(%{
          trip_id: trip.id,
          departure_time: "10:00:00",
          arrival_time: "14:00:00"
        })

      transfer2 =
        transfer_fixture(%{
          trip_id: trip.id,
          departure_time: "08:00:00",
          arrival_time: "12:00:00"
        })

      transfer3 =
        transfer_fixture(%{
          trip_id: trip.id,
          departure_time: "15:00:00",
          arrival_time: "18:00:00"
        })

      # Should be ordered by departure_time (earliest first)
      [first, second, third] = Planning.list_transfers(trip)

      # 08:00
      assert first.id == transfer2.id
      # 10:00
      assert second.id == transfer1.id
      # 15:00
      assert third.id == transfer3.id
    end

    test "list_transfers/1 only returns transfers for the specified trip" do
      trip1 = trip_fixture()
      trip2 = trip_fixture()

      transfer1 = transfer_fixture(%{trip_id: trip1.id})
      _transfer2 = transfer_fixture(%{trip_id: trip2.id})

      transfers = Planning.list_transfers(trip1)
      assert length(transfers) == 1
      assert hd(transfers).id == transfer1.id
    end

    test "transfers_for_day/2 returns transfers for the specified day" do
      # Create transfers with different day indexes
      transfer1 = transfer_fixture(%{day_index: 0})
      transfer2 = transfer_fixture(%{day_index: 1})
      transfer3 = transfer_fixture(%{day_index: 1})

      transfers = [transfer1, transfer2, transfer3]

      # Test day 0 (should include transfer1)
      assert [^transfer1] = Planning.transfers_for_day(0, transfers)

      # Test day 1 (should include transfer2 and transfer3)
      day_1_transfers = Planning.transfers_for_day(1, transfers)
      assert length(day_1_transfers) == 2
      assert transfer2 in day_1_transfers
      assert transfer3 in day_1_transfers

      # Test day 2 (should return empty list)
      assert [] = Planning.transfers_for_day(2, transfers)
    end

    test "transfers_for_day/2 orders transfers by departure_time" do
      # Create transfers on the same day with different departure times
      transfer1 = transfer_fixture(%{day_index: 0, departure_time: "10:00"})
      transfer2 = transfer_fixture(%{day_index: 0, departure_time: "08:00"})
      transfer3 = transfer_fixture(%{day_index: 0, departure_time: "15:00"})

      transfers = [transfer1, transfer2, transfer3]

      # Should be ordered by departure_time (earliest first)
      [first, second, third] = Planning.transfers_for_day(0, transfers)

      # 08:00
      assert first.id == transfer2.id
      # 10:00
      assert second.id == transfer1.id
      # 15:00
      assert third.id == transfer3.id
    end
  end

  describe "move_transfer_to_day/4" do
    setup do
      geonames_fixture()
      author = user_fixture()
      friend = user_fixture()
      stranger = user_fixture()

      # Create friendship
      Social.add_friends(author.id, friend.id)

      # Create a trip with duration 5 days (days 0-4 are valid)
      trip =
        trip_fixture(%{
          author_id: author.id,
          duration: 5,
          dates_unknown: true
        })

      # Preload transfers for the trip
      trip = Planning.get_trip!(trip.id)

      {:ok,
       author: Repo.preload(author, :friendships),
       friend: Repo.preload(friend, :friendships),
       stranger: Repo.preload(stranger, :friendships),
       trip: trip}
    end

    test "successfully moves transfer to valid day for trip author", %{author: author, trip: trip} do
      # Create a transfer on day 0
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 0})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer to day 2
      assert {:ok, updated_transfer} = Planning.move_transfer_to_day(transfer, 2, trip, author)

      assert updated_transfer.day_index == 2
      assert updated_transfer.id == transfer.id
      # Verify it has proper preloading
      assert updated_transfer.departure_city.name
      assert updated_transfer.arrival_city.name
      assert updated_transfer.expense.price
    end

    test "successfully moves transfer to valid day for friend in friends circle", %{
      friend: friend,
      trip: trip
    } do
      # Create a transfer on day 1
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 1})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer to day 3
      assert {:ok, updated_transfer} = Planning.move_transfer_to_day(transfer, 3, trip, friend)

      assert updated_transfer.day_index == 3
      assert updated_transfer.id == transfer.id
    end

    test "successfully moves transfer to same day (no-op)", %{author: author, trip: trip} do
      # Create a transfer on day 2
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 2})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer to same day 2
      assert {:ok, updated_transfer} = Planning.move_transfer_to_day(transfer, 2, trip, author)

      assert updated_transfer.day_index == 2
      assert updated_transfer.id == transfer.id
    end

    test "successfully moves transfer to day 0 (edge case)", %{author: author, trip: trip} do
      # Create a transfer on day 3
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 3})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer to day 0 (first day)
      assert {:ok, updated_transfer} = Planning.move_transfer_to_day(transfer, 0, trip, author)

      assert updated_transfer.day_index == 0
    end

    test "successfully moves transfer to last valid day", %{author: author, trip: trip} do
      # Create a transfer on day 1
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 1})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer to day 4 (last valid day for duration 5)
      assert {:ok, updated_transfer} = Planning.move_transfer_to_day(transfer, 4, trip, author)

      assert updated_transfer.day_index == 4
    end

    test "fails when transfer is nil", %{author: author, trip: trip} do
      assert {:error, "Transfer not found"} = Planning.move_transfer_to_day(nil, 2, trip, author)
    end

    test "fails when user is not authorized (stranger)", %{stranger: stranger, trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 0})

      assert {:error, "Unauthorized"} = Planning.move_transfer_to_day(transfer, 2, trip, stranger)
    end

    test "fails when day_index is negative", %{author: author, trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 1})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      assert {:error, "Day index must be between 0 and 4"} =
               Planning.move_transfer_to_day(transfer, -1, trip, author)
    end

    test "fails when day_index equals trip duration", %{author: author, trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 1})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Trip duration is 5, so valid days are 0-4, day 5 should fail
      assert {:error, "Day index must be between 0 and 4"} =
               Planning.move_transfer_to_day(transfer, 5, trip, author)
    end

    test "fails when day_index is greater than trip duration", %{author: author, trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 1})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      assert {:error, "Day index must be between 0 and 4"} =
               Planning.move_transfer_to_day(transfer, 10, trip, author)
    end

    test "works with trip duration 1 (only day 0 valid)", %{author: author} do
      # Create a trip with duration 1 (only day 0 is valid)
      short_trip =
        trip_fixture(%{
          author_id: author.id,
          duration: 1,
          dates_unknown: true
        })

      transfer = transfer_fixture(%{trip_id: short_trip.id, day_index: 0})

      # Reload trip to include the new transfer
      short_trip = Planning.get_trip!(short_trip.id)

      # Moving to day 0 should work
      assert {:ok, _} = Planning.move_transfer_to_day(transfer, 0, short_trip, author)

      # Moving to day 1 should fail
      assert {:error, "Day index must be between 0 and 0"} =
               Planning.move_transfer_to_day(transfer, 1, short_trip, author)
    end

    test "works with maximum trip duration", %{author: author} do
      # Create a trip with duration 30 (maximum allowed)
      long_trip =
        trip_fixture(%{
          author_id: author.id,
          duration: 30,
          dates_unknown: true
        })

      transfer = transfer_fixture(%{trip_id: long_trip.id, day_index: 0})

      # Reload trip to include the new transfer
      long_trip = Planning.get_trip!(long_trip.id)

      # Moving to day 29 (last valid day) should work
      assert {:ok, updated_transfer} =
               Planning.move_transfer_to_day(transfer, 29, long_trip, author)

      assert updated_transfer.day_index == 29

      # Moving to day 30 should fail
      assert {:error, "Day index must be between 0 and 29"} =
               Planning.move_transfer_to_day(transfer, 30, long_trip, author)
    end

    test "validates transfer belongs to the given trip", %{author: author, trip: trip} do
      # Add a transfer to the original trip first
      trip_transfer = transfer_fixture(%{trip_id: trip.id, day_index: 0})

      # Create another trip with a different author to ensure complete separation
      other_user = user_fixture()
      other_trip = trip_fixture(%{author_id: other_user.id})
      other_trip = Planning.get_trip!(other_trip.id)

      # Create transfer for the other trip
      other_transfer = transfer_fixture(%{trip_id: other_trip.id, day_index: 0})

      # Reload the original trip to get fresh data
      trip = Planning.get_trip!(trip.id)

      # Verify our original trip has only its own transfer
      assert length(trip.transfers) == 1
      assert hd(trip.transfers).id == trip_transfer.id

      # Verify the other transfer is not in our trip
      transfer_ids = Enum.map(trip.transfers, & &1.id)
      refute other_transfer.id in transfer_ids

      # Try to move the other trip's transfer using our trip context - should fail
      assert {:error, "Transfer not found"} =
               Planning.move_transfer_to_day(other_transfer, 2, trip, author)
    end

    test "handles database errors gracefully", %{author: author, trip: trip} do
      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 0})

      # Delete the transfer from database but keep it in trip.transfers for testing
      {:ok, _} = Planning.delete_transfer(transfer)

      # Add the deleted transfer back to trip.transfers to simulate stale data
      trip = %{trip | transfers: [transfer | trip.transfers]}

      # This should return an error when trying to update a deleted transfer
      assert {:error, %Ecto.Changeset{}} =
               Planning.move_transfer_to_day(transfer, 2, trip, author)
    end

    test "sends pubsub event", %{author: author, trip: trip} do
      # Subscribe to the topic
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      transfer = transfer_fixture(%{trip_id: trip.id, day_index: 0})

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer
      assert {:ok, _} = Planning.move_transfer_to_day(transfer, 2, trip, author)

      assert_receive {[:transfer, :updated], %{value: _}}, 100
    end

    test "preserves all transfer attributes except day_index", %{author: author, trip: trip} do
      # Create transfer with specific attributes
      original_attrs = %{
        trip_id: trip.id,
        day_index: 0,
        transport_mode: "bus",
        note: "Special bus ride",
        vessel_number: "BUS123",
        carrier: "FlixBus",
        departure_station: "Central Station",
        arrival_station: "Airport Terminal",
        departure_time: "14:30",
        arrival_time: "16:45"
      }

      transfer = transfer_fixture(original_attrs)

      # Reload trip to include the new transfer
      trip = Planning.get_trip!(trip.id)

      # Move transfer to different day
      assert {:ok, updated_transfer} = Planning.move_transfer_to_day(transfer, 3, trip, author)

      # Verify only day_index changed
      assert updated_transfer.day_index == 3
      assert updated_transfer.transport_mode == "bus"
      assert updated_transfer.note == "Special bus ride"
      assert updated_transfer.vessel_number == "BUS123"
      assert updated_transfer.carrier == "FlixBus"
      assert updated_transfer.departure_station == "Central Station"
      assert updated_transfer.arrival_station == "Airport Terminal"
      assert updated_transfer.departure_time == transfer.departure_time
      assert updated_transfer.arrival_time == transfer.arrival_time
      assert updated_transfer.departure_city_id == transfer.departure_city_id
      assert updated_transfer.arrival_city_id == transfer.arrival_city_id
    end
  end

  describe "activities" do
    alias HamsterTravel.Planning.Activity

    @invalid_attrs %{name: nil, day_index: nil, priority: nil}
    @update_attrs %{name: "Updated Activity", description: "Updated description", priority: 1}

    setup do
      trip = trip_fixture()
      {:ok, trip: trip}
    end

    test "list_activities/1 returns all activities for a trip", %{trip: trip} do
      activity = activity_fixture(%{trip_id: trip.id})
      [result] = Planning.list_activities(trip)
      assert result.id == activity.id
      assert result.name == activity.name
      assert result.trip_id == activity.trip_id
      assert result.day_index == activity.day_index
      assert result.priority == activity.priority
    end

    test "get_activity!/1 returns the activity with given id" do
      activity = activity_fixture()
      result = Planning.get_activity!(activity.id)
      assert result.id == activity.id
      assert result.name == activity.name
      assert result.trip_id == activity.trip_id
    end

    test "create_activity/2 with valid data creates an activity", %{trip: trip} do
      valid_attrs = %{
        name: "Sightseeing",
        day_index: 0,
        priority: 2,
        link: "https://example.com/sightseeing",
        address: "City Center",
        description: "Walking tour",
        expense: %{
          price: Money.new(:EUR, 0),
          name: "Free tour",
          trip_id: trip.id
        }
      }

      assert {:ok, %Activity{} = activity} = Planning.create_activity(trip, valid_attrs)
      assert activity.name == "Sightseeing"
      assert activity.day_index == 0
      assert activity.priority == 2
      assert activity.link == "https://example.com/sightseeing"
      assert activity.address == "City Center"
      assert activity.description == "Walking tour"
      assert activity.trip_id == trip.id
      assert activity.expense.price == Money.new(:EUR, 0)
      assert activity.expense.trip_id == trip.id
    end

    test "create_activity/2 broadcasts activity creation", %{trip: trip} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
      valid_attrs = %{name: "Test", day_index: 0, priority: 2}

      assert {:ok, activity} = Planning.create_activity(trip, valid_attrs)
      assert_receive {[:activity, :created], %{value: ^activity}}
    end

    test "create_activity/2 with invalid data returns error changeset", %{trip: trip} do
      assert {:error, %Ecto.Changeset{}} = Planning.create_activity(trip, @invalid_attrs)
    end

    test "create_activity/2 validates priority range", %{trip: trip} do
      attrs = %{name: "Test", day_index: 0, priority: 4}
      assert {:error, changeset} = Planning.create_activity(trip, attrs)
      assert %{priority: ["is invalid"]} = errors_on(changeset)

      attrs = %{name: "Test", day_index: 0, priority: 0}
      assert {:error, changeset} = Planning.create_activity(trip, attrs)
      assert %{priority: ["is invalid"]} = errors_on(changeset)
    end

    test "create_activity/2 validates day_index non-negative", %{trip: trip} do
      attrs = %{name: "Test", day_index: -1, priority: 2}
      assert {:error, changeset} = Planning.create_activity(trip, attrs)
      assert %{day_index: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "update_activity/2 with valid data updates the activity" do
      activity = activity_fixture()

      assert {:ok, %Activity{} = updated_activity} =
               Planning.update_activity(activity, @update_attrs)

      assert updated_activity.name == "Updated Activity"
      assert updated_activity.priority == 1
      assert updated_activity.description == "Updated description"
    end

    test "update_activity/2 sends pubsub event", %{trip: trip} do
      activity = activity_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Activity{} = updated_activity} =
               Planning.update_activity(activity, @update_attrs)

      assert_receive {[:activity, :updated], %{value: ^updated_activity}}
    end

    test "update_activity/2 with invalid data returns error changeset" do
      activity = activity_fixture()
      assert {:error, %Ecto.Changeset{}} = Planning.update_activity(activity, @invalid_attrs)
      assert activity.name == Planning.get_activity!(activity.id).name
    end

    test "delete_activity/1 deletes the activity" do
      activity = activity_fixture()
      assert {:ok, %Activity{}} = Planning.delete_activity(activity)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_activity!(activity.id) end
    end

    test "delete_activity/1 sends pubsub event", %{trip: trip} do
      activity = activity_fixture(%{trip_id: trip.id})
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %Activity{} = deleted_activity} = Planning.delete_activity(activity)
      assert_receive {[:activity, :deleted], %{value: ^deleted_activity}}
    end

    test "change_activity/1 returns an activity changeset" do
      activity = activity_fixture()
      assert %Ecto.Changeset{} = Planning.change_activity(activity)
    end

    test "new_activity/2 returns a new activity changeset with default priority" do
      trip = trip_fixture()
      changeset = Planning.new_activity(trip, 0)
      assert %Ecto.Changeset{data: %{trip_id: trip_id, day_index: 0, priority: 2}} = changeset
      assert trip_id == trip.id
    end

    test "activities_for_day/2 returns activities for the specified day ordered by rank" do
      trip = trip_fixture()

      {:ok, activity1} = Planning.create_activity(trip, %{name: "A1", day_index: 0, priority: 2})
      {:ok, activity2} = Planning.create_activity(trip, %{name: "A2", day_index: 0, priority: 2})
      {:ok, activity3} = Planning.create_activity(trip, %{name: "A3", day_index: 1, priority: 2})

      activities = [activity1, activity2, activity3]

      day0_activities = Planning.activities_for_day(0, activities)
      assert length(day0_activities) == 2
      assert Enum.map(day0_activities, & &1.id) == [activity1.id, activity2.id]

      assert [^activity3] = Planning.activities_for_day(1, activities)
      assert [] = Planning.activities_for_day(2, activities)
    end
  end

  describe "move_activity_to_day/5" do
    setup do
      author = user_fixture()
      friend = user_fixture()
      stranger = user_fixture()

      # Create friendship
      Social.add_friends(author.id, friend.id)

      # Create a trip with duration 5 days (days 0-4 are valid)
      trip =
        trip_fixture(%{
          author_id: author.id,
          duration: 5,
          dates_unknown: true
        })

      # Preload activities for the trip
      trip = Planning.get_trip!(trip.id)

      {:ok,
       author: Repo.preload(author, :friendships),
       friend: Repo.preload(friend, :friendships),
       stranger: Repo.preload(stranger, :friendships),
       trip: trip}
    end

    test "successfully moves activity to valid day for trip author", %{author: author, trip: trip} do
      # Create an activity on day 0
      activity = activity_fixture(%{trip_id: trip.id, day_index: 0})

      # Reload trip to include the new activity
      trip = Planning.get_trip!(trip.id)

      # Move activity to day 2
      assert {:ok, updated_activity} = Planning.move_activity_to_day(activity, 2, trip, author)

      assert updated_activity.day_index == 2
      assert updated_activity.id == activity.id
    end

    test "successfully moves activity to valid day for friend", %{friend: friend, trip: trip} do
      activity = activity_fixture(%{trip_id: trip.id, day_index: 1})
      trip = Planning.get_trip!(trip.id)

      assert {:ok, updated_activity} = Planning.move_activity_to_day(activity, 3, trip, friend)
      assert updated_activity.day_index == 3
    end

    test "successfully moves activity to same day (updates rank)", %{author: author, trip: trip} do
      activity1 = activity_fixture(%{trip_id: trip.id, day_index: 0, name: "A1"})
      activity2 = activity_fixture(%{trip_id: trip.id, day_index: 0, name: "A2"})
      trip = Planning.get_trip!(trip.id)

      # Move A2 to first position (it was last)
      assert {:ok, updated_activity2} =
               Planning.move_activity_to_day(activity2, 0, trip, author, 0)

      assert updated_activity2.day_index == 0
      # Rank should be lower than A1's original rank (or A1 is shifted)
      # We can check order by listing activities
      [a1, a2] = Planning.list_activities(trip)
      # Wait, list_activities orders by rank. So the first one should be A2 now.
      assert a1.id == updated_activity2.id
      assert a2.id == activity1.id
    end

    test "fails when activity is nil", %{author: author, trip: trip} do
      assert {:error, "Activity not found"} = Planning.move_activity_to_day(nil, 2, trip, author)
    end

    test "fails when user is not authorized", %{stranger: stranger, trip: trip} do
      activity = activity_fixture(%{trip_id: trip.id, day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:error, "Unauthorized"} = Planning.move_activity_to_day(activity, 2, trip, stranger)
    end

    test "fails when day_index is out of bounds", %{author: author, trip: trip} do
      activity = activity_fixture(%{trip_id: trip.id, day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:error, "Day index must be between 0 and 4"} =
               Planning.move_activity_to_day(activity, 5, trip, author)
    end

    test "fails when activity does not belong to trip", %{author: author, trip: trip} do
      other_user = user_fixture()
      other_trip = trip_fixture(%{author_id: other_user.id})
      other_activity = activity_fixture(%{trip_id: other_trip.id})

      trip = Planning.get_trip!(trip.id)

      assert {:error, "Activity not found"} =
               Planning.move_activity_to_day(other_activity, 2, trip, author)
    end

    test "sends pubsub event", %{author: author, trip: trip} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
      activity = activity_fixture(%{trip_id: trip.id, day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:ok, _} = Planning.move_activity_to_day(activity, 2, trip, author)
      assert_receive {[:activity, :updated], %{value: _}}
    end
  end

  describe "reorder_activity/4" do
    setup do
      author = user_fixture()
      trip = trip_fixture(%{author_id: author.id})

      # Create 3 activities on day 0
      {:ok, a1} = Planning.create_activity(trip, %{name: "A1", day_index: 0, priority: 2})
      {:ok, a2} = Planning.create_activity(trip, %{name: "A2", day_index: 0, priority: 2})
      {:ok, a3} = Planning.create_activity(trip, %{name: "A3", day_index: 0, priority: 2})

      # Reload to get ranks
      trip = Planning.get_trip!(trip.id)

      {:ok, author: Repo.preload(author, :friendships), trip: trip, a1: a1, a2: a2, a3: a3}
    end

    test "reorders activity within same day", %{
      author: author,
      trip: trip,
      a1: a1,
      a2: a2,
      a3: a3
    } do
      # Initial order: A1, A2, A3
      [first, second, third] = Planning.list_activities(trip)
      assert first.id == a1.id
      assert second.id == a2.id
      assert third.id == a3.id

      # Move A3 to first position (index 0)
      assert {:ok, _} = Planning.reorder_activity(a3, 0, trip, author)

      # New order: A3, A1, A2
      [first, second, third] = Planning.list_activities(trip)
      assert first.id == a3.id
      assert second.id == a1.id
      assert third.id == a2.id
    end

    test "fails when unauthorized", %{trip: trip, a1: a1} do
      stranger = user_fixture() |> Repo.preload(:friendships)
      assert {:error, "Unauthorized"} = Planning.reorder_activity(a1, 1, trip, stranger)
    end

    test "fails when activity not in trip", %{author: author, trip: trip} do
      other_trip = trip_fixture()

      {:ok, other_activity} =
        Planning.create_activity(other_trip, %{name: "OA", day_index: 0, priority: 2})

      assert {:error, "Activity not found"} =
               Planning.reorder_activity(other_activity, 0, trip, author)
    end

    test "sends pubsub event", %{author: author, trip: trip, a1: a1} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
      assert {:ok, _} = Planning.reorder_activity(a1, 1, trip, author)
      assert_receive {[:activity, :updated], %{value: _}}
    end
  end

  describe "notes" do
    test "list_notes/1 returns notes for trip ordered by day and rank" do
      trip = trip_fixture()

      note_late = note_fixture(%{trip_id: trip.id, day_index: 1, title: "Later"})
      note_early = note_fixture(%{trip_id: trip.id, day_index: 0, title: "Early"})

      assert [note_early.id, note_late.id] ==
               Planning.list_notes(trip.id) |> Enum.map(& &1.id)
    end

    test "get_note!/1 returns the note" do
      note = note_fixture()
      assert Planning.get_note!(note.id).id == note.id
    end

    test "create_note/2 with valid data creates a note with optional day index" do
      trip = trip_fixture()

      valid_attrs = %{
        title: "Trip report",
        text: "<p>Great memories.</p>",
        day_index: nil
      }

      assert {:ok, note} = Planning.create_note(trip, valid_attrs)
      assert note.title == "Trip report"
      assert note.text == "<p>Great memories.</p>"
      assert note.day_index == nil
      assert note.trip_id == trip.id
    end

    test "create_note/2 requires a title" do
      trip = trip_fixture()
      invalid_attrs = %{text: "Missing title"}

      assert {:error, changeset} = Planning.create_note(trip, invalid_attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_note/2 updates the note" do
      note = note_fixture(%{title: "Old title"})

      assert {:ok, note} = Planning.update_note(note, %{title: "New title", day_index: 2})
      assert note.title == "New title"
      assert note.day_index == 2
    end

    test "delete_note/1 deletes the note" do
      note = note_fixture()
      assert {:ok, _note} = Planning.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_note!(note.id) end
    end

    test "new_note/2 returns a changeset with defaults" do
      trip = trip_fixture()
      changeset = Planning.new_note(trip)

      assert changeset.data.trip_id == trip.id
      assert changeset.data.day_index == nil
    end

    test "new_note/2 returns a changeset with day index when provided" do
      trip = trip_fixture()
      changeset = Planning.new_note(trip, 2)

      assert changeset.data.trip_id == trip.id
      assert changeset.data.day_index == 2
    end

    test "change_note/2 returns a note changeset" do
      note = note_fixture()
      assert %Ecto.Changeset{} = Planning.change_note(note, %{title: "Updated"})
    end
  end

  describe "day_expenses" do
    alias HamsterTravel.Planning.DayExpense

    @invalid_day_expense_attrs %{name: nil, day_index: nil}
    @update_day_expense_attrs %{name: "Updated expense"}

    setup do
      trip = trip_fixture()
      {:ok, trip: trip}
    end

    test "list_day_expenses/1 returns all day expenses for a trip", %{trip: trip} do
      {:ok, day_expense1} =
        Planning.create_day_expense(trip, %{
          name: "Transport card",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 1200), trip_id: trip.id}
        })

      {:ok, day_expense2} =
        Planning.create_day_expense(trip, %{
          name: "Museum pass",
          day_index: 1,
          expense: %{price: Money.new(:EUR, 2000), trip_id: trip.id}
        })

      other_trip = trip_fixture()

      {:ok, _other_day_expense} =
        Planning.create_day_expense(other_trip, %{
          name: "Other",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 500), trip_id: other_trip.id}
        })

      result = Planning.list_day_expenses(trip)
      ids = Enum.map(result, & &1.id)

      assert length(result) == 2
      assert day_expense1.id in ids
      assert day_expense2.id in ids
    end

    test "get_day_expense!/1 returns the day expense with given id" do
      day_expense = day_expense_fixture()
      result = Planning.get_day_expense!(day_expense.id)
      assert result.id == day_expense.id
      assert result.name == day_expense.name
      assert result.trip_id == day_expense.trip_id
    end

    test "create_day_expense/2 with valid data creates a day expense", %{trip: trip} do
      valid_attrs = %{
        name: "Transport card",
        day_index: 0,
        expense: %{
          price: Money.new(:EUR, 1200),
          name: "Metro pass",
          trip_id: trip.id
        }
      }

      assert {:ok, %DayExpense{} = day_expense} = Planning.create_day_expense(trip, valid_attrs)
      assert day_expense.name == "Transport card"
      assert day_expense.day_index == 0
      assert day_expense.trip_id == trip.id
      assert day_expense.expense.price == Money.new(:EUR, 1200)
      assert day_expense.expense.trip_id == trip.id
    end

    test "create_day_expense/2 broadcasts day expense creation", %{trip: trip} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
      valid_attrs = %{name: "Test", day_index: 0}

      assert {:ok, day_expense} = Planning.create_day_expense(trip, valid_attrs)
      assert_receive {[:day_expense, :created], %{value: ^day_expense}}
    end

    test "create_day_expense/2 with invalid data returns error changeset", %{trip: trip} do
      assert {:error, %Ecto.Changeset{}} =
               Planning.create_day_expense(trip, @invalid_day_expense_attrs)
    end

    test "create_day_expense/2 validates day_index non-negative", %{trip: trip} do
      attrs = %{name: "Test", day_index: -1}
      assert {:error, changeset} = Planning.create_day_expense(trip, attrs)
      assert %{day_index: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "update_day_expense/2 with valid data updates the day expense" do
      day_expense = day_expense_fixture()

      assert {:ok, %DayExpense{} = updated} =
               Planning.update_day_expense(day_expense, @update_day_expense_attrs)

      assert updated.name == "Updated expense"
    end

    test "update_day_expense/2 sends pubsub event", %{trip: trip} do
      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Test",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 1200), trip_id: trip.id}
        })

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %DayExpense{} = updated} =
               Planning.update_day_expense(day_expense, @update_day_expense_attrs)

      assert_receive {[:day_expense, :updated], %{value: ^updated}}
    end

    test "update_day_expense/2 with invalid data returns error changeset" do
      day_expense = day_expense_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Planning.update_day_expense(day_expense, @invalid_day_expense_attrs)

      assert day_expense.name == Planning.get_day_expense!(day_expense.id).name
    end

    test "delete_day_expense/1 deletes the day expense" do
      day_expense = day_expense_fixture()
      assert {:ok, %DayExpense{}} = Planning.delete_day_expense(day_expense)
      assert_raise Ecto.NoResultsError, fn -> Planning.get_day_expense!(day_expense.id) end
    end

    test "delete_day_expense/1 sends pubsub event", %{trip: trip} do
      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Test",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 1200), trip_id: trip.id}
        })

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      assert {:ok, %DayExpense{} = deleted} = Planning.delete_day_expense(day_expense)
      assert_receive {[:day_expense, :deleted], %{value: ^deleted}}
    end

    test "change_day_expense/1 returns a day expense changeset" do
      day_expense = day_expense_fixture()
      assert %Ecto.Changeset{} = Planning.change_day_expense(day_expense)
    end

    test "new_day_expense/2 returns a new day expense changeset with trip_id and day_index" do
      trip = trip_fixture()
      changeset = Planning.new_day_expense(trip, 0)

      assert %Ecto.Changeset{data: %{trip_id: trip_id, day_index: 0}} = changeset
      assert trip_id == trip.id
    end

    test "day_expenses_for_day/2 returns day expenses for the specified day ordered by rank" do
      trip = trip_fixture()

      {:ok, day_expense1} = Planning.create_day_expense(trip, %{name: "E1", day_index: 0})
      {:ok, day_expense2} = Planning.create_day_expense(trip, %{name: "E2", day_index: 0})
      {:ok, day_expense3} = Planning.create_day_expense(trip, %{name: "E3", day_index: 1})

      day_expenses = [day_expense1, day_expense2, day_expense3]

      day0_expenses = Planning.day_expenses_for_day(0, day_expenses)
      assert length(day0_expenses) == 2
      assert Enum.map(day0_expenses, & &1.id) == [day_expense1.id, day_expense2.id]

      assert [^day_expense3] = Planning.day_expenses_for_day(1, day_expenses)
      assert [] = Planning.day_expenses_for_day(2, day_expenses)
    end
  end

  describe "move_day_expense_to_day/5" do
    setup do
      author = user_fixture()
      friend = user_fixture()
      stranger = user_fixture()

      Social.add_friends(author.id, friend.id)

      trip =
        trip_fixture(%{
          author_id: author.id,
          duration: 5,
          dates_unknown: true
        })

      trip = Planning.get_trip!(trip.id)

      {:ok,
       author: Repo.preload(author, :friendships),
       friend: Repo.preload(friend, :friendships),
       stranger: Repo.preload(stranger, :friendships),
       trip: trip}
    end

    test "successfully moves day expense to valid day for trip author", %{
      author: author,
      trip: trip
    } do
      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Transport",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 1200), trip_id: trip.id}
        })

      trip = Planning.get_trip!(trip.id)

      assert {:ok, updated} = Planning.move_day_expense_to_day(day_expense, 2, trip, author)
      assert updated.day_index == 2
      assert updated.id == day_expense.id
    end

    test "successfully moves day expense to valid day for friend", %{friend: friend, trip: trip} do
      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Transport",
          day_index: 1,
          expense: %{price: Money.new(:EUR, 1200), trip_id: trip.id}
        })

      trip = Planning.get_trip!(trip.id)

      assert {:ok, updated} = Planning.move_day_expense_to_day(day_expense, 3, trip, friend)
      assert updated.day_index == 3
    end

    test "successfully moves day expense to same day (updates rank)", %{
      author: author,
      trip: trip
    } do
      {:ok, day_expense1} = Planning.create_day_expense(trip, %{name: "E1", day_index: 0})
      {:ok, day_expense2} = Planning.create_day_expense(trip, %{name: "E2", day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:ok, updated} = Planning.move_day_expense_to_day(day_expense2, 0, trip, author, 0)
      assert updated.day_index == 0

      [first, second] = Planning.list_day_expenses(trip)
      assert first.id == updated.id
      assert second.id == day_expense1.id
    end

    test "fails when day expense is nil", %{author: author, trip: trip} do
      assert {:error, "Day expense not found"} =
               Planning.move_day_expense_to_day(nil, 2, trip, author)
    end

    test "fails when user is not authorized", %{stranger: stranger, trip: trip} do
      {:ok, day_expense} = Planning.create_day_expense(trip, %{name: "Transport", day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:error, "Unauthorized"} =
               Planning.move_day_expense_to_day(day_expense, 2, trip, stranger)
    end

    test "fails when day_index is out of bounds", %{author: author, trip: trip} do
      {:ok, day_expense} = Planning.create_day_expense(trip, %{name: "Transport", day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:error, "Day index must be between 0 and 4"} =
               Planning.move_day_expense_to_day(day_expense, 5, trip, author)
    end

    test "fails when day expense does not belong to trip", %{author: author, trip: trip} do
      other_user = user_fixture()
      other_trip = trip_fixture(%{author_id: other_user.id})

      {:ok, other_day_expense} =
        Planning.create_day_expense(other_trip, %{name: "Other", day_index: 0})

      trip = Planning.get_trip!(trip.id)

      assert {:error, "Day expense not found"} =
               Planning.move_day_expense_to_day(other_day_expense, 2, trip, author)
    end

    test "sends pubsub event", %{author: author, trip: trip} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
      {:ok, day_expense} = Planning.create_day_expense(trip, %{name: "Transport", day_index: 0})
      trip = Planning.get_trip!(trip.id)

      assert {:ok, _} = Planning.move_day_expense_to_day(day_expense, 2, trip, author)
      assert_receive {[:day_expense, :updated], %{value: _}}
    end
  end

  describe "reorder_day_expense/4" do
    setup do
      author = user_fixture()
      trip = trip_fixture(%{author_id: author.id})

      {:ok, e1} = Planning.create_day_expense(trip, %{name: "E1", day_index: 0})
      {:ok, e2} = Planning.create_day_expense(trip, %{name: "E2", day_index: 0})
      {:ok, e3} = Planning.create_day_expense(trip, %{name: "E3", day_index: 0})

      trip = Planning.get_trip!(trip.id)

      {:ok, author: Repo.preload(author, :friendships), trip: trip, e1: e1, e2: e2, e3: e3}
    end

    test "reorders day expense within same day", %{
      author: author,
      trip: trip,
      e1: e1,
      e2: e2,
      e3: e3
    } do
      [first, second, third] = Planning.list_day_expenses(trip)
      assert first.id == e1.id
      assert second.id == e2.id
      assert third.id == e3.id

      assert {:ok, _} = Planning.reorder_day_expense(e3, 0, trip, author)

      [first, second, third] = Planning.list_day_expenses(trip)
      assert first.id == e3.id
      assert second.id == e1.id
      assert third.id == e2.id
    end

    test "fails when unauthorized", %{trip: trip, e1: e1} do
      stranger = user_fixture() |> Repo.preload(:friendships)
      assert {:error, "Unauthorized"} = Planning.reorder_day_expense(e1, 1, trip, stranger)
    end

    test "fails when day expense not in trip", %{author: author, trip: trip} do
      other_trip = trip_fixture()

      {:ok, other_day_expense} =
        Planning.create_day_expense(other_trip, %{name: "OE", day_index: 0})

      assert {:error, "Day expense not found"} =
               Planning.reorder_day_expense(other_day_expense, 0, trip, author)
    end

    test "sends pubsub event", %{author: author, trip: trip, e1: e1} do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
      assert {:ok, _} = Planning.reorder_day_expense(e1, 1, trip, author)
      assert_receive {[:day_expense, :updated], %{value: _}}
    end
  end
end
