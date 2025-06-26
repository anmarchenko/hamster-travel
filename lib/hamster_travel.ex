defmodule HamsterTravel do
  @moduledoc """
  HamsterTravel keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def filter_transfers_by_day(transfers, day_index) do
    transfers
    |> Enum.filter(fn tr -> tr.day_index == day_index end)
    |> Enum.sort(fn l, r -> l.time_from <= r.time_from end)
  end

  def filter_activities_by_day(activities, day_index) do
    activities
    |> Enum.filter(fn act -> act.day_index == day_index end)
    |> Enum.sort(fn l, r -> l.position <= r.position end)
  end

  def filter_expenses_by_day(expenses, day_index) do
    expenses
    |> Enum.filter(fn ex -> ex.day_index == day_index end)
  end

  def find_note_by_day(notes, day_index) do
    case Enum.filter(notes, fn n -> n.day_index == day_index end) do
      [] ->
        nil

      [note | _] ->
        note
    end
  end
end
