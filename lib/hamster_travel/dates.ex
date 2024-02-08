defmodule HamsterTravel.Dates do
  @moduledoc """
  Dates related functions
  """

  def duration(start_date, end_date) do
    start_date = parse_iso_date_or(start_date)
    end_date = parse_iso_date_or(end_date)

    if start_date && end_date do
      Date.diff(end_date, start_date) + 1
    else
      0
    end
  end

  # return date when it is already elixir date
  def parse_iso_date_or(date, default \\ nil)
  def parse_iso_date_or(nil, _default), do: nil
  def parse_iso_date_or(%Date{} = date, _default), do: date

  def parse_iso_date_or(date, default) do
    case Date.from_iso8601(date) do
      {:ok, date} -> date
      {:error, _} -> default
    end
  end
end
