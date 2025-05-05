defmodule HamsterTravelWeb.Planning.ShowTrip do
  @moduledoc """
  Trip page
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Cldr
  alias HamsterTravelWeb.Planning.TabItinerary
  alias HamsterTravelWeb.Planning.Trips.Tabs.TabActivity

  @tabs ["activities", "itinerary", "catering", "documents", "report"]

  @impl true
  def mount(%{"trip_slug" => slug} = params, _session, socket) do
    trip = Planning.fetch_trip!(slug, socket.assigns.current_user)

    socket =
      socket
      |> assign(mobile_menu: :plan_tabs)
      |> assign(active_tab: fetch_tab(params))
      |> assign(active_nav: active_nav(trip))
      |> assign(page_title: trip.name)
      |> assign(trip: trip)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(active_tab: fetch_tab(params))

    {:noreply, socket}
  end

  def render_tab(%{active_tab: "itinerary"} = assigns) do
    ~H"""
    <.live_component module={TabItinerary} id={"trip-#{@trip.id}-itinerary"} trip={@trip} />
    """
  end

  def render_tab(%{active_tab: "activities"} = assigns) do
    ~H"""
    <.live_component module={TabActivity} id={"trip-#{@trip.id}-activities"} trip={@trip} />
    """
  end

  defp active_nav(%{status: "0_draft"}), do: drafts_nav_item()
  defp active_nav(_), do: plans_nav_item()

  defp fetch_tab(%{"tab" => tab})
       when tab in @tabs,
       do: tab

  defp fetch_tab(_), do: "itinerary"
end
