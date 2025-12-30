defmodule HamsterTravel do
  @moduledoc """
  HamsterTravel keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

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
