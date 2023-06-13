defmodule HamsterTravel.PlanningFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Planning` context.
  """

  @doc """
  Generate a trip.
  """
  def trip_fixture(attrs \\ %{}) do
    {:ok, trip} =
      attrs
      |> Enum.into(%{
        currency: "some currency",
        dates_unknown: true,
        duration: 42,
        end_date: ~D[2023-06-12],
        name: "some name",
        people_count: 42,
        private: true,
        start_date: ~D[2023-06-12],
        status: "some status"
      })
      |> HamsterTravel.Planning.create_trip()

    trip
  end
end
