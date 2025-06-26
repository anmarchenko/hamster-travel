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
      |> assign(active_accommodation_adding_component_id: nil)

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
    handle_entity_event(:destination, :created, created_destination, socket)
  end

  @impl true
  def handle_info({[:destination, :updated], %{value: updated_destination}}, socket) do
    handle_entity_event(:destination, :updated, updated_destination, socket)
  end

  @impl true
  def handle_info({[:destination, :deleted], %{value: deleted_destination}}, socket) do
    handle_entity_event(:destination, :deleted, deleted_destination, socket)
  end

  @impl true
  def handle_info({[:accommodation, :created], %{value: created_accommodation}}, socket) do
    handle_entity_event(:accommodation, :created, created_accommodation, socket)
  end

  @impl true
  def handle_info({[:accommodation, :updated], %{value: updated_accommodation}}, socket) do
    handle_entity_event(:accommodation, :updated, updated_accommodation, socket)
  end

  @impl true
  def handle_info({[:accommodation, :deleted], %{value: deleted_accommodation}}, socket) do
    handle_entity_event(:accommodation, :deleted, deleted_accommodation, socket)
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
      accommodations={@trip.accommodations}
      accommodations_outside={accommodations_outside(@trip)}
      destinations={@trip.destinations}
      destinations_outside={destinations_outside(@trip)}
      transfers={[]}
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

  defp accommodations_outside(trip) do
    trip.accommodations
    |> Enum.filter(fn accommodation ->
      accommodation.start_day >= trip.duration
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
    case get_creation_component_info(component_type) do
      {module, active_assign_key} ->
        trip = socket.assigns.trip

        for i <- 0..(trip.duration - 1) do
          component_id = "#{component_type}-new-#{i}"

          send_update(module,
            id: component_id,
            edit: Map.get(socket.assigns, active_assign_key) == component_id
          )
        end

        socket

      nil ->
        socket
    end
  end

  defp get_creation_component_info(component_type) do
    case component_type do
      "destination" ->
        {HamsterTravelWeb.Planning.DestinationNew, :active_destination_adding_component_id}

      "accommodation" ->
        {HamsterTravelWeb.Planning.AccommodationNew, :active_accommodation_adding_component_id}

      _ ->
        nil
    end
  end

  defp handle_entity_event(entity_type, operation, entity, socket) do
    # Preload associations based on entity type
    entity = preload_entity_associations(entity_type, entity)

    # Get the plural form for the trip field
    entities_key = get_entities_key(entity_type)

    # Update the trip's entity list based on operation
    updated_entities =
      update_entities_list(
        Map.get(socket.assigns.trip, entities_key),
        operation,
        entity
      )

    # Update trip with new entities list and reload countries if destinations changed
    trip =
      socket.assigns.trip
      |> Map.put(entities_key, updated_entities)
      |> maybe_preload_countries(entity_type)

    socket = assign(socket, trip: trip)
    {:noreply, socket}
  end

  defp preload_entity_associations(:destination, entity), do: Repo.preload(entity, [:city])
  defp preload_entity_associations(:accommodation, entity), do: Repo.preload(entity, [:expense])

  defp get_entities_key(:destination), do: :destinations
  defp get_entities_key(:accommodation), do: :accommodations

  defp maybe_preload_countries(trip, :destination), do: Repo.preload(trip, :countries)
  defp maybe_preload_countries(trip, _), do: trip

  defp update_entities_list(entities, :created, entity) do
    entities ++ [entity]
  end

  defp update_entities_list(entities, :updated, entity) do
    Enum.map(entities, fn existing_entity ->
      if existing_entity.id == entity.id, do: entity, else: existing_entity
    end)
  end

  defp update_entities_list(entities, :deleted, entity) do
    Enum.reject(entities, fn existing_entity ->
      existing_entity.id == entity.id
    end)
  end
end
