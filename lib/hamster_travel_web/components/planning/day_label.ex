defmodule HamsterTravelWeb.Planning.DayLabel do
  @moduledoc """
  Label for a day in planning (could be date with a week day or just a number)
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def day_label(assigns) do
    assigns
    |> set_attributes([start_date: nil], required: [:index])
    |> extend_class("", prefix_replace: false)
    |> render()
  end

  defp render(%{index: index, start_date: nil} = assigns) do
    ~H"""
    <%= gettext("Day") %> <%= index + 1 %>
    """
  end

  defp render(%{start_date: start_date, index: index} = assigns) do
    ~H"""
    <%= Formatter.date_with_weekday(Date.add(start_date, index)) %>
    """
  end
end
