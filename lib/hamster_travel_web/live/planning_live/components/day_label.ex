defmodule HamsterTravelWeb.Planning.DayLabel do
  @moduledoc """
  Label for a day in planning (could be date with a week day or just a number)
  """
  use HamsterTravelWeb, :html

  attr(:start_date, Date, default: nil)
  attr(:day_index, :integer, required: true)

  def day_label(assigns) do
    render(assigns)
  end

  defp render(%{start_date: nil} = assigns) do
    ~H"""
    {gettext("Day")} {@day_index + 1}
    """
  end

  defp render(assigns) do
    ~H"""
    {Formatter.date_with_weekday(Date.add(@start_date, @day_index))}
    """
  end
end
