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
      return_to={@return_to}
    />
    """
  end

  @impl true
  def mount(params, _session, socket) do
    is_draft = Map.get(params, "draft", false)
    return_to = return_to(params)

    socket =
      with %{"copy" => trip_id} <- params,
           trip when trip != nil <- Planning.get_trip(trip_id),
           true <- Policy.authorized?(:copy, trip, socket.assigns.current_user) do
        socket
        |> assign(copy_from: trip)
        |> assign(back_url: trip_url(trip.slug, :show, return_to))
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
      |> assign(return_to: return_to)
      |> assign(is_draft: is_draft)

    {:ok, socket}
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
