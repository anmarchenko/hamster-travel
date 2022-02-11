defmodule HamsterTravelWeb.Planning.Place do
  @moduledoc """
  Live component responsible for showing and editing places (aka cities to visit)
  """
  use HamsterTravelWeb, :live_component

  def update(%{place: place}, socket) do
    socket =
      socket
      |> assign(place: place)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, place: place} = assigns) do
    ~H"""
      <div class="flex flex-row gap-2 items-center">
        <Flags.flag size={16} country={place.city.country} />
        <%= place.city.name %>
      </div>
    """
  end
end
