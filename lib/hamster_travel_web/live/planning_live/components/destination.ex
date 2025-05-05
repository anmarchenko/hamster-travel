defmodule HamsterTravelWeb.Planning.Destination do
  @moduledoc """
  Live component responsible for showing and editing destinations (aka cities to visit)
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <span>
      <.inline>
        <.flag size={20} country={@destination.city.country_code} />
        {Geo.city_name(@destination.city)}
      </.inline>
    </span>
    """
  end
end
