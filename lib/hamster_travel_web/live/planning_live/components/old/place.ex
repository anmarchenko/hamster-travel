defmodule HamsterTravelWeb.Planning.Place do
  @moduledoc """
  Live component responsible for showing and editing places (aka cities to visit)
  """
  use HamsterTravelWeb, :live_component

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
        <.flag size={20} country={@place.city.country} />
        {@place.city.name}
      </.inline>
    </span>
    """
  end
end
