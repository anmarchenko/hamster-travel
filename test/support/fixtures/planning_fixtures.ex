defmodule HamsterTravel.PlanningFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Planning` context.
  """

  import HamsterTravel.GeoFixtures

  @doc """
  Generate a trip.
  """
  def trip_fixture(attrs \\ %{}) do
    user = HamsterTravel.AccountsFixtures.user_fixture()

    {:ok, trip} =
      attrs
      |> Enum.into(%{
        name: "Venice on weekend",
        dates_unknown: false,
        start_date: ~D[2023-06-12],
        end_date: ~D[2023-06-14],
        currency: "EUR",
        status: "1_planned",
        private: false,
        people_count: 2
      })
      |> HamsterTravel.Planning.create_trip(user)

    trip
  end

  @doc """
  Generate a destination.
  """
  def destination_fixture(attrs \\ %{}) do
    # Setup geonames data and get a city
    geonames_fixture()
    # Berlin
    city = HamsterTravel.Geo.find_city_by_geonames_id("2950159")
    trip = trip_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        city_id: city.id,
        end_day: 10,
        start_day: 0
      })

    {:ok, destination} =
      HamsterTravel.Planning.create_destination(trip, attrs)

    destination
  end

  @doc """
  Generate an expense.
  """
  def expense_fixture(attrs \\ %{}) do
    trip = trip_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        price: Money.new(:EUR, 1500),
        name: "Hotel booking"
      })

    {:ok, expense} =
      HamsterTravel.Planning.create_expense(trip, attrs)

    expense
  end

  @doc """
  Generate an accommodation.
  """
  def accommodation_fixture(attrs \\ %{}) do
    trip = trip_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        name: "Grand Hotel Vienna",
        link: "https://example.com/hotel",
        address: "123 Main Street, Vienna",
        note: "Great location near the city center",
        start_day: 0,
        end_day: 2,
        expense: %{
          price: Money.new(:EUR, 15_000),
          name: "Hotel booking",
          trip_id: trip.id
        }
      })

    {:ok, accommodation} =
      HamsterTravel.Planning.create_accommodation(trip, attrs)

    accommodation
  end

  @doc """
  Generate a transfer.
  """
  def transfer_fixture(attrs \\ %{}) do
    # Setup geonames data and get cities
    geonames_fixture()

    # Berlin and Hamburg
    berlin = HamsterTravel.Geo.find_city_by_geonames_id("2950159")
    hamburg = HamsterTravel.Geo.find_city_by_geonames_id("2911298")
    trip = trip_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        transport_mode: "train",
        departure_city_id: berlin.id,
        arrival_city_id: hamburg.id,
        departure_time: "08:00",
        arrival_time: "12:00",
        note: "Fast train connection",
        vessel_number: "ICE 123",
        carrier: "Deutsche Bahn",
        departure_station: "Berlin Hauptbahnhof",
        arrival_station: "Hamburg Hauptbahnhof",
        day_index: 0,
        expense: %{
          price: Money.new(:EUR, 8900),
          name: "Train ticket",
          trip_id: trip.id
        }
      })

    {:ok, transfer} =
      HamsterTravel.Planning.create_transfer(trip, attrs)

    transfer
  end

  @doc """
  Generate an activity.
  """
  def activity_fixture(attrs \\ %{}) do
    trip = trip_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        name: "Visit Museum",
        day_index: 0,
        priority: 2,
        link: "https://example.com/museum",
        address: "Museum Street 1",
        description: "A very nice museum",
        expense: %{
          price: Money.new(:EUR, 2000),
          name: "Museum ticket",
          trip_id: trip.id
        }
      })

    {:ok, activity} =
      HamsterTravel.Planning.create_activity(trip, attrs)

    activity
  end

  @doc """
  Generate a day expense.
  """
  def day_expense_fixture(attrs \\ %{}) do
    trip = trip_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        name: "Transport card",
        day_index: 0,
        trip_id: trip.id,
        expense: %{
          price: Money.new(:EUR, 1200),
          name: "Metro pass",
          trip_id: trip.id
        }
      })

    changeset =
      HamsterTravel.Planning.DayExpense.changeset(
        %HamsterTravel.Planning.DayExpense{trip_id: trip.id},
        attrs
      )

    {:ok, day_expense} = HamsterTravel.Repo.insert(changeset)

    day_expense
  end
end
