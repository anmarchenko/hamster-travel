defmodule HamsterTravelWeb.Planning.ShowTrip do
  @moduledoc """
  Trip page
  """
  use HamsterTravelWeb, :live_view

  require Logger

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
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
          <.shorts trip={@trip} budget={@budget} display_currency={@display_currency} />
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
      <.render_tab
        trip={@trip}
        active_tab={@active_tab}
        budget={@budget}
        display_currency={@display_currency}
      />
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
      |> assign(budget: Planning.calculate_budget(trip))
      # get from user settings
      |> assign(display_currency: "EUR")
      |> assign(active_destination_adding_component_id: nil)
      |> assign(active_accommodation_adding_component_id: nil)
      |> assign(active_transfer_adding_component_id: nil)

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
  def handle_info({[:transfer, :created], %{value: created_transfer}}, socket) do
    handle_entity_event(:transfer, :created, created_transfer, socket)
  end

  @impl true
  def handle_info({[:transfer, :updated], %{value: updated_transfer}}, socket) do
    handle_entity_event(:transfer, :updated, updated_transfer, socket)
  end

  @impl true
  def handle_info({[:transfer, :deleted], %{value: deleted_transfer}}, socket) do
    handle_entity_event(:transfer, :deleted, deleted_transfer, socket)
  end

  @impl true
  def handle_info({[:activity, :created], %{value: created_activity}}, socket) do
    handle_entity_event(:activity, :created, created_activity, socket)
  end

  @impl true
  def handle_info({[:activity, :updated], %{value: updated_activity}}, socket) do
    handle_entity_event(:activity, :updated, updated_activity, socket)
  end

  @impl true
  def handle_info({[:activity, :deleted], %{value: deleted_activity}}, socket) do
    handle_entity_event(:activity, :deleted, deleted_activity, socket)
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

  @impl true
  def handle_event(
        "move_transfer",
        %{"transfer_id" => transfer_id, "new_day_index" => new_day_index},
        socket
      ) do
    transfer = find_transfer_in_trip(transfer_id, socket.assigns.trip)

    case Planning.move_transfer_to_day(
           transfer,
           new_day_index,
           socket.assigns.trip,
           socket.assigns.current_user
         ) do
      {:ok, _updated_transfer} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(socket, :error, gettext("Failed to move transfer: %{reason}", reason: reason))

        Logger.error("Failed to move transfer: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "move_activity",
        %{
          "activity_id" => activity_id,
          "new_day_index" => new_day_index,
          "position" => position
        },
        socket
      ) do
    activity = find_activity_in_trip(activity_id, socket.assigns.trip)
    new_day_index = ensure_int(new_day_index)
    position = ensure_int(position)

    case Planning.move_activity_to_day(
           activity,
           new_day_index,
           socket.assigns.trip,
           socket.assigns.current_user,
           position
         ) do
      {:ok, _updated_activity} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(socket, :error, gettext("Failed to move activity: %{reason}", reason: reason))

        Logger.error("Failed to move activity: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "reorder_activity",
        %{"activity_id" => activity_id, "position" => position},
        socket
      ) do
    activity = find_activity_in_trip(activity_id, socket.assigns.trip)
    position = ensure_int(position)

    case Planning.reorder_activity(
           activity,
           position,
           socket.assigns.trip,
           socket.assigns.current_user
         ) do
      {:ok, _updated_activity} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(
            socket,
            :error,
            gettext("Failed to reorder activity: %{reason}", reason: reason)
          )

        Logger.error("Failed to reorder activity: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  defp ensure_int(val) when is_binary(val), do: String.to_integer(val)
  defp ensure_int(val) when is_integer(val), do: val
  defp ensure_int(val), do: val

  def render_tab(%{active_tab: "itinerary"} = assigns) do
    ~H"""
    <.tab_itinerary
      trip={@trip}
      accommodations={@trip.accommodations}
      accommodations_outside={accommodations_outside(@trip)}
      destinations={@trip.destinations}
      destinations_outside={destinations_outside(@trip)}
      transfers={@trip.transfers}
      transfers_outside={transfers_outside(@trip)}
      budget={@budget}
      display_currency={@display_currency}
    />
    """
  end

  def render_tab(%{active_tab: "activities"} = assigns) do
    ~H"""
    <.tab_activity
      trip={@trip}
      destinations={@trip.destinations}
      destinations_outside={destinations_outside(@trip)}
      activities={@trip.activities}
      budget={@budget}
      display_currency={@display_currency}
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

  defp transfers_outside(trip) do
    trip.transfers
    |> Enum.filter(fn transfer ->
      transfer.day_index >= trip.duration
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

      "transfer" ->
        {HamsterTravelWeb.Planning.TransferNew, :active_transfer_adding_component_id}

      "activity" ->
        {HamsterTravelWeb.Planning.ActivityNew, :active_activity_adding_component_id}

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

    # Recalculate budget if accommodation changed
    socket =
      socket
      |> assign(trip: trip)
      |> maybe_recalculate_budget(entity_type, trip)

    {:noreply, socket}
  end

  defp preload_entity_associations(:destination, entity),
    do: Repo.preload(entity, city: Geo.city_preloading_query())

  defp preload_entity_associations(:accommodation, entity), do: Repo.preload(entity, [:expense])

  defp preload_entity_associations(:activity, entity), do: Repo.preload(entity, [:expense])

  defp preload_entity_associations(:transfer, entity),
    do:
      Repo.preload(entity, [
        :expense,
        departure_city: Geo.city_preloading_query(),
        arrival_city: Geo.city_preloading_query()
      ])

  defp get_entities_key(:destination), do: :destinations
  defp get_entities_key(:accommodation), do: :accommodations
  defp get_entities_key(:activity), do: :activities
  defp get_entities_key(:transfer), do: :transfers

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

  defp maybe_recalculate_budget(socket, :accommodation, trip) do
    assign(socket, budget: Planning.calculate_budget(trip))
  end

  defp maybe_recalculate_budget(socket, :transfer, trip) do
    assign(socket, budget: Planning.calculate_budget(trip))
  end

  defp maybe_recalculate_budget(socket, :activity, trip) do
    assign(socket, budget: Planning.calculate_budget(trip))
  end

  defp maybe_recalculate_budget(socket, _entity_type, _trip), do: socket

  defp find_transfer_in_trip(transfer_id, %Trip{transfers: transfers}) do
    Enum.find(transfers, &(Integer.to_string(&1.id) == transfer_id))
  end

  defp find_activity_in_trip(activity_id, %Trip{activities: activities}) do
    Enum.find(activities, &(Integer.to_string(&1.id) == activity_id))
  end
end
