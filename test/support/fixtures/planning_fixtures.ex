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
end
