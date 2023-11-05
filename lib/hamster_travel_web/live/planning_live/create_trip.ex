defmodule HamsterTravelWeb.Planning.CreateTrip do
  @moduledoc """
  Create trip form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Planning

  alias HamsterTravelWeb.Planning.TripForm

  @impl true
  def mount(_params, _session, socket) do
    changeset = Planning.new_trip()

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign(form: to_form(changeset))
      |> assign(back_url: plans_url())
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Create a new trip"))

    {:ok, socket}
  end

  def create_trip(socket, trip_params) do
    trip_params
    |> Planning.create_trip(socket.assigns.current_user)
    |> result(socket)
  end

  def result({:ok, trip}, socket) do
    socket =
      socket
      |> push_redirect(to: ~p"/trips/#{trip.slug}")

    {:noreply, socket}
  end

  def result({:error, changeset}, socket) do
    {:noreply, assign(socket, %{changeset: changeset, form: to_form(changeset)})}
  end
end
