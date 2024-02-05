defmodule HamsterTravelWeb.Planning.CreateTrip do
  @moduledoc """
  Create trip form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Planning

  alias HamsterTravelWeb.Planning.Trips.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Create a new trip"))
      |> assign(back_url: plans_url())

    {:ok, socket}
  end
end
