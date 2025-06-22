defmodule HamsterTravelWeb.Planning.ShowTrip do
  @moduledoc """
  Trip page
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning
  alias HamsterTravel.Repo
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
        Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")
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
      |> assign(active_destination_adding_component_id: nil)

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

  @impl true
  def handle_info({:start_adding, component_type, component_id}, socket) do
    assign_key = get_key_for_component_adding_active_state_assign(component_type)

    socket =
      socket
      |> assign(assign_key, component_id)
      |> send_edit_state_to_entity_creation_components(component_type)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:finish_adding, component_type}, socket) do
    assign_key = get_key_for_component_adding_active_state_assign(component_type)

    socket =
      socket
      |> assign(assign_key, nil)
      |> send_edit_state_to_entity_creation_components(component_type)

    {:noreply, socket}
  end

  def render_tab(%{active_tab: "itinerary"} = assigns) do
    ~H"""
    <.tab_itinerary
      trip={@trip}
      destinations={@trip.destinations}
      destinations_outside={destinations_outside(@trip)}
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
      destinations_outside={destinations_outside(@trip)}
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

  defp destinations_outside(trip) do
    trip.destinations
    |> Enum.filter(fn destination ->
      destination.start_day >= trip.duration
    end)
  end

  defp get_key_for_component_adding_active_state_assign(component_type) do
    case component_type do
      "destination" -> :active_destination_adding_component_id
      "accommodation" -> :active_accommodation_adding_component_id
      "transfer" -> :active_transfer_adding_component_id
      "activity" -> :active_activity_adding_component_id
      _ -> raise ArgumentError, "Unsupported component type: #{component_type}"
    end
  end

  defp send_edit_state_to_entity_creation_components(socket, component_type) do
    case component_type do
      "destination" ->
        # Update all DestinationNew components
        trip = socket.assigns.trip

        for i <- 0..(trip.duration - 1) do
          send_update(HamsterTravelWeb.Planning.DestinationNew,
            id: "destination-new-#{i}",
            edit: socket.assigns.active_destination_adding_component_id == "destination-new-#{i}"
          )
        end

        socket

      _ ->
        socket
    end
  end
end
