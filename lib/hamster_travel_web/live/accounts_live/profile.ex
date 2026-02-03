defmodule HamsterTravelWeb.Accounts.Profile do
  @moduledoc """
  User profile
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Planning

  @impl true
  def mount(_params, _session, socket) do
    profile_stats = Planning.profile_stats(socket.assigns.current_user)

    socket =
      socket
      |> assign(
        page_title: gettext("My profile"),
        visited_countries: profile_stats.visited_countries,
        total_trips: profile_stats.total_trips,
        countries_count: profile_stats.countries,
        days_on_the_road: profile_stats.days_on_the_road
      )

    {:ok, socket}
  end
end
