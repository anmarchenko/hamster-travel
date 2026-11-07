defmodule HamsterTravel.Planning.DayProjectionTest do
  use ExUnit.Case, async: true

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.DayProjection

  test "day collections preserve helper ordering, clipped ranges, and outside day budgets" do
    trip = %{
      duration: 3,
      destinations: [%{start_day: -2, end_day: 1}, %{start_day: 1, end_day: 8}],
      accommodations: [%{start_day: 2, end_day: 2}],
      transfers: [transfer(4, ~T[12:00:00], 10), transfer(1, ~T[13:00:00], 0)],
      activities: [activity(1, 2, 10), activity(1, 1, 20), activity(4, 1, 10), activity(5, 1, 0)],
      day_expenses: [
        day_expense(6, 2, 20),
        day_expense(6, 1, 10),
        day_expense(0, 1, 0),
        day_expense(7, 1, 0)
      ]
    }

    projection = DayProjection.build(trip)

    for day <- 0..7 do
      if day < trip.duration do
        assert Map.get(projection.destinations, day, []) ==
                 Planning.items_for_day(day, trip.destinations)

        assert Map.get(projection.accommodations, day, []) ==
                 Planning.items_for_day(day, trip.accommodations)
      end

      assert Map.get(projection.activities, day, []) ==
               Planning.activities_for_day(day, trip.activities)

      assert Map.get(projection.transfers, day, []) ==
               Planning.transfers_for_day(day, trip.transfers)

      assert Map.get(projection.day_expenses, day, []) ==
               Planning.day_expenses_for_day(day, trip.day_expenses)
    end

    assert projection.budget_days_outside == [4, 6, 7]
    assert projection.budget_transfers == %{4 => [hd(trip.transfers)]}
    assert projection.budget_activities[1] == Enum.reverse(Enum.take(trip.activities, 2))
    assert projection.budget_day_expenses == Map.take(projection.day_expenses, [6, 7])

    updated = DayProjection.build(%{trip | activities: [activity(2, 1, 30)], duration: 1})
    assert updated.activities == %{2 => [activity(2, 1, 30)]}
    assert updated.destinations == %{0 => [hd(trip.destinations)]}
    assert updated.budget_days_outside == [2, 4, 6, 7]
  end

  defp activity(day, rank, price),
    do: %{day_index: day, rank: rank, expense: %{price: Money.new(:EUR, price)}}

  defp transfer(day, time, price),
    do: %{day_index: day, departure_time: time, expense: %{price: Money.new(:EUR, price)}}

  defp day_expense(day, rank, price),
    do: %{day_index: day, rank: rank, expense: %{price: Money.new(:EUR, price)}}
end
