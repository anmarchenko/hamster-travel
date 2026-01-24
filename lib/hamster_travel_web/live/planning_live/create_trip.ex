defmodule HamsterTravelWeb.Planning.CreateTrip do
  @moduledoc """
  Create trip form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Policy
  alias HamsterTravelWeb.Planning.TripForm

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      id="create-trip-form"
      module={TripForm}
      action={:new}
      current_user={@current_user}
      copy_from={@copy_from}
      back_url={@back_url}
      is_draft={@is_draft}
    />
    """
  end

  @impl true
  def mount(params, _session, socket) do
    is_draft = Map.get(params, "draft", false)

    socket =
      with %{"copy" => trip_id} <- params,
           trip when trip != nil <- Planning.get_trip(trip_id),
           true <- Policy.authorized?(:copy, trip, socket.assigns.current_user) do
        socket
        |> assign(copy_from: trip)
        |> assign(back_url: trip_url(trip.slug))
      else
        _ ->
          socket
          |> assign(copy_from: nil)
          |> assign(back_url: plans_url())
      end

    socket =
      socket
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Create a new trip"))
      |> assign(is_draft: is_draft)

    {:ok, socket}
  end
end
