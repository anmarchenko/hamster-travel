defmodule HamsterTravelWeb.Planning.ShowTrip do
  @moduledoc """
  Trip page
  """
  alias HamsterTravel.Repo
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Cldr

  @tabs ["itinerary", "activities"]

  @impl true
  def render(assigns) do
    ~H"""
    <.container full class="!mt-* mt-4">
      <div class="flex flex-col-reverse sm:flex-row">
        <div class="flex-1 flex flex-col gap-y-4">
          <.header>
            {@trip.name}
            <:subtitle>
              {Cldr.year_with_month(@trip.start_date)}
            </:subtitle>
          </.header>
          <.shorts trip={@trip} />
          <.inline :if={@current_user} class="gap-3 text-xs sm:text-base">
            <.button link_type="live_redirect" to={trip_url(@trip.slug, :edit)} color="secondary">
              <.icon_text icon="hero-pencil" label={gettext("Edit")} />
            </.button>
            <%!-- <.link href={trip_url(@trip.slug, :copy)}>
          <%= gettext("Make a copy") %>
        </.link>
        <.link href={trip_url(@trip.slug, :pdf)}>
          <%= gettext("Export as PDF") %>
        </.link>
        <.link href={trip_url(@trip.slug, :delete)}>
          <%= gettext("Delete") %>
        </.link> --%>
          </.inline>
          <.status_row trip={@trip} />
        </div>
        <div class="">
          <%!-- <img
        :if={@trip.cover}
        class="max-h-52 mb-4 sm:mb-0 sm:h-36 sm:w-auto sm:max-h-full shadow-lg rounded-md"
        src={@trip.cover}
      /> --%>
        </div>
      </div>
    </.container>

    <.container
      full
      class="!mt-* !p-* py-4 sm:py-6 px-6 sm:px-10 mb-10 mt-4 bg-white dark:bg-zinc-800 rounded-md"
    >
      <.planning_tabs trip={@trip} active_tab={@active_tab} />
      <.render_tab trip={@trip} active_tab={@active_tab} />
    </.container>
    """
  end

  @impl true
  def mount(%{"trip_slug" => slug} = params, _session, socket) do
    trip = Planning.fetch_trip!(slug, socket.assigns.current_user)

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "trip_destinations:#{trip.id}")
        socket
      else
        socket
      end

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

  @impl true
  def handle_info({[:destination, :created], %{value: created_destination}}, socket) do
    # Preload city before sending to component
    created_destination = Repo.preload(created_destination, [:city])

    trip =
      socket.assigns.trip
      |> Map.put(:destinations, socket.assigns.trip.destinations ++ [created_destination])

    trip = Repo.preload(trip, :countries)

    socket =
      socket
      |> assign(trip: trip)

    {:noreply, socket}
  end

  @impl true
  def handle_info({[:destination, :updated], %{value: updated_destination}}, socket) do
    # Preload city before sending to component
    updated_destination = Repo.preload(updated_destination, [:city])

    trip =
      socket.assigns.trip
      |> Map.put(
        :destinations,
        Enum.map(socket.assigns.trip.destinations, fn destination ->
          if destination.id == updated_destination.id, do: updated_destination, else: destination
        end)
      )

    trip = Repo.preload(trip, :countries)

    socket =
      socket
      |> assign(trip: trip)

    {:noreply, socket}
  end

  @impl true
  def handle_info({[:destination, :deleted], %{value: deleted_destination}}, socket) do
    trip =
      socket.assigns.trip
      |> Map.put(
        :destinations,
        Enum.reject(socket.assigns.trip.destinations, fn destination ->
          destination.id == deleted_destination.id
        end)
      )

    trip = Repo.preload(trip, :countries)

    socket =
      socket
      |> assign(trip: trip)

    {:noreply, socket}
  end

  def render_tab(%{active_tab: "itinerary"} = assigns) do
    ~H"""
    <.tab_itinerary
      trip={@trip}
      destinations={@trip.destinations}
      transfers={[]}
      hotels={[]}
      budget={0}
    />
    """
  end

  def render_tab(%{active_tab: "activities"} = assigns) do
    ~H"""
    <.tab_activity
      trip={@trip}
      budget={0}
      destinations={@trip.destinations}
      activities={[]}
      notes={[]}
      expenses={[]}
    />
    """
  end

  defp active_nav(%{status: "0_draft"}), do: drafts_nav_item()
  defp active_nav(_), do: plans_nav_item()

  defp fetch_tab(%{"tab" => tab})
       when tab in @tabs,
       do: tab

  defp fetch_tab(_), do: "itinerary"
end
