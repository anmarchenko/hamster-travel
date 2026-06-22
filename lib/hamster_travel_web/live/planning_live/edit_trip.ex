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
      return_to={@return_to}
      trip={@trip}
    />
    """
  end

  @impl true
  def mount(%{"trip_slug" => slug} = params, _session, socket) do
    user = socket.assigns.current_user
    trip = Planning.fetch_trip!(slug, user)
    return_to = return_to(params)

    if Policy.authorized?(:edit, trip, user) do
      socket =
        socket
        |> assign(active_nav: plans_nav_item())
        |> assign(page_title: gettext("Edit trip"))
        |> assign(back_url: trip_url(slug, :show, return_to))
        |> assign(return_to: return_to)
        |> assign(trip: trip)

      {:ok, socket}
    else
      raise HamsterTravelWeb.Errors.NotAuthorized
    end
  end

  defp return_to(%{"return_to" => return_to}) when is_binary(return_to) do
    case URI.parse(return_to) do
      %{scheme: nil, host: nil, path: path, query: query} when path in ["/plans", "/drafts"] ->
        URI.to_string(%URI{path: path, query: query})

      _uri ->
        nil
    end
  end

  defp return_to(_params), do: nil
end
