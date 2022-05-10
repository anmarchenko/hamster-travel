defmodule HamsterTravelWeb.Planning.PlanComponents do
  @moduledoc """
  This component renders plan items/cards
  """
  use HamsterTravelWeb, :component

  import HamsterTravelWeb.Icons.{Airplane, Bus, Car, Ship, Taxi, Train}

  alias HamsterTravelWeb.Planning.Place

  def status_badge(assigns) do
    classes =
      class_list([
        {assigns[:class], true},
        {"flex items-center h-6 px-3 text-xs font-semibold rounded-full", true},
        {status_colors(assigns), true}
      ])

    ~H"""
    <span class={classes}>
      <%= Gettext.gettext(HamsterTravelWeb.Gettext, @status) %>
    </span>
    """
  end

  def places_list(%{places: places, day_index: day_index} = assigns) do
    places_for_day = HamsterTravel.filter_places_by_day(places, day_index)

    ~H"""
    <%= for place <- places_for_day do %>
      <.live_component
        module={Place}
        id={"places-#{place.id}-day-#{day_index}"}
        place={place}
        day_index={day_index}
      />
    <% end %>
    """
  end

  def day(%{index: index, start_date: start_date} = assigns) do
    if start_date != nil do
      ~H"""
      <%= Formatter.date_with_weekday(Date.add(start_date, index)) %>
      """
    else
      ~H"""
      <%= gettext("Day") %> <%= index + 1 %>
      """
    end
  end

  defp status_colors(%{status: "finished"}),
    do: "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-100"

  defp status_colors(%{status: "planned"}),
    do: "text-yellow-500 bg-yellow-200 dark:bg-yellow-800 dark:text-yellow-200"

  defp status_colors(%{status: "draft"}),
    do: "text-pink-500 bg-pink-100 dark:bg-pink-800 dark:text-pink-100"
end
