defmodule HamsterTravelWeb.Planning.Places do
  @moduledoc """
  Live component responsible for showing and editing places (aka cities to visit)
  """
  use HamsterTravelWeb, :live_component

  def update(%{plan: plan, day_index: day_index}, socket) do
    places = HamsterTravel.find_places_by_day(plan, day_index)

    socket =
      socket
      |> assign(places: places)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, places: places} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-2">
      <%= for place <- places do %>
        <div class="flex flex-row gap-2 items-center">
          <Flags.flag size={16} country={place.city.country} />
          <%= place.city.name %>
        </div>
      <% end %>
    </div>
    """
  end
end
