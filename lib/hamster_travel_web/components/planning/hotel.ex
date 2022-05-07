defmodule HamsterTravelWeb.Planning.Hotel do
  @moduledoc """
  Live component responsible for showing and editing hotels
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Icons.HomeSimple

  def update(%{hotel: hotel}, socket) do
    socket =
      socket
      |> assign(hotel: hotel)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, hotel: hotel} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1">
      <div class="flex flex-row gap-2 items-center">
        <.home_simple />
        <%= hotel.name %>
      </div>
      <UI.icon_text>
        <Icons.budget />
        <%= Formatter.format_money(hotel.price, hotel.price_currency) %>
      </UI.icon_text>
      <UI.secondary_text>
        <%= hotel.comment %>
      </UI.secondary_text>
      <UI.external_links links={hotel.links} />
    </div>
    """
  end
end
