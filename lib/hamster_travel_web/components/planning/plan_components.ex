defmodule HamsterTravelWeb.Planning.PlanComponents do
  @moduledoc """
  This component renders plan items/cards
  """
  use HamsterTravelWeb, :component

  import HamsterTravelWeb.Icons.{Airplane, Bus, Car, Ship, Taxi, Train}

  alias HamsterTravelWeb.Planning.Place

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
end
