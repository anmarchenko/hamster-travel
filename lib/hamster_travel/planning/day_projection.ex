defmodule HamsterTravel.Planning.DayProjection do
  @moduledoc "Shared, ordered day collections for the trip views."

  @spec build(map()) :: map()
  def build(trip) do
    projection = %{
      destinations: ranged(trip.destinations, trip.duration),
      accommodations: ranged(trip.accommodations, trip.duration),
      transfers: singular(trip.transfers, & &1.departure_time),
      activities: singular(trip.activities, & &1.rank),
      day_expenses: singular(trip.day_expenses, & &1.rank),
      notes: singular(trip.notes, & &1.rank)
    }

    budget_transfers = priced(projection.transfers)
    budget_activities = priced(projection.activities)

    budget_days =
      (Map.keys(budget_transfers) ++
         Map.keys(budget_activities) ++ Map.keys(projection.day_expenses))
      |> Enum.filter(&(is_integer(&1) and &1 >= 0))
      |> Enum.uniq()
      |> Enum.sort()

    Map.merge(projection, %{
      budget_transfers: budget_transfers,
      budget_activities: budget_activities,
      budget_days: budget_days
    })
  end

  defp ranged(items, duration) do
    Enum.reduce(Enum.reverse(items), %{}, fn item, result ->
      first = max(0, item.start_day)
      last = min(duration - 1, item.end_day)

      if first <= last do
        Enum.reduce(first..last, result, fn day, acc ->
          Map.update(acc, day, [item], &[item | &1])
        end)
      else
        result
      end
    end)
  end

  defp singular(items, sorter) do
    items
    |> Enum.group_by(& &1.day_index)
    |> Map.new(fn {day, entries} -> {day, Enum.sort_by(entries, sorter)} end)
  end

  defp priced(days) do
    days
    |> Enum.map(fn {day, entries} -> {day, Enum.filter(entries, &non_zero_expense?/1)} end)
    |> Enum.reject(fn {_day, entries} -> entries == [] end)
    |> Map.new()
  end

  defp non_zero_expense?(%{expense: %{price: %Money{} = price}}),
    do: not Money.equal?(price, Money.new(price.currency, 0))

  defp non_zero_expense?(_), do: false
end
