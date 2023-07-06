defmodule HamsterTravel.PlanningFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Planning` context.
  """

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
end
