defmodule HamsterTravelWeb.Planning.EditTrip do
  @moduledoc """
  Edit trip form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Policy

  alias HamsterTravelWeb.Planning.TripForm

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      id="edit-trip-form"
      module={TripForm}
      action={:edit}
      current_user={@current_user}
      back_url={@back_url}
      trip={@trip}
    />
    """
  end

  @impl true
  def mount(%{"trip_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    trip = Planning.fetch_trip!(slug, user)

    if Policy.authorized?(:edit, trip, user) do
      socket =
        socket
        |> assign(active_nav: plans_nav_item())
        |> assign(page_title: gettext("Edit trip"))
        |> assign(back_url: trip_url(slug))
        |> assign(trip: trip)

      {:ok, socket}
    else
      raise HamsterTravelWeb.Errors.NotAuthorized
    end
  end
end
