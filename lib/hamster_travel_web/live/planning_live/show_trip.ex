defmodule HamsterTravelWeb.Planning.ShowTrip do
  @moduledoc """
  Trip page
  """
  use HamsterTravelWeb, :live_view

  require Logger

  import HamsterTravelWeb.Planning.PlanningComponents
  import HamsterTravelWeb.Icons.Airplane

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo
  alias HamsterTravelWeb.Cldr
  alias HamsterTravelWeb.CoreComponents

  alias HamsterTravelWeb.Planning.{
    Accommodation,
    AccommodationNew,
    Activity,
    ActivityNew,
    DayExpense,
    DayExpenseNew,
    FoodExpense,
    Note,
    NoteNew,
    Destination,
    DestinationNew,
    Transfer,
    TransferNew
  }

  @tabs ["itinerary", "activities", "notes"]

  @impl true
  def render(assigns) do
    ~H"""
    <.container full class="mt-*! mt-4">
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
        <div>
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
      class="mt-*! p-*! py-4 sm:py-6 px-6 sm:px-10 mb-10 mt-4 bg-white dark:bg-zinc-800 rounded-md"
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

  # EVENT HANDLERS

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
      |> assign(active_activity_adding_component_id: nil)
      |> assign(active_day_expense_adding_component_id: nil)
      |> assign(active_note_adding_component_id: nil)

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
  def handle_info({[:day_expense, :created], %{value: created_day_expense}}, socket) do
    handle_entity_event(:day_expense, :created, created_day_expense, socket)
  end

  @impl true
  def handle_info({[:day_expense, :updated], %{value: updated_day_expense}}, socket) do
    handle_entity_event(:day_expense, :updated, updated_day_expense, socket)
  end

  @impl true
  def handle_info({[:day_expense, :deleted], %{value: deleted_day_expense}}, socket) do
    handle_entity_event(:day_expense, :deleted, deleted_day_expense, socket)
  end

  @impl true
  def handle_info({[:note, :created], %{value: created_note}}, socket) do
    handle_entity_event(:note, :created, created_note, socket)
  end

  @impl true
  def handle_info({[:note, :updated], %{value: updated_note}}, socket) do
    handle_entity_event(:note, :updated, updated_note, socket)
  end

  @impl true
  def handle_info({[:note, :deleted], %{value: deleted_note}}, socket) do
    handle_entity_event(:note, :deleted, deleted_note, socket)
  end

  @impl true
  def handle_info({[:food_expense, :updated], %{value: updated_food_expense}}, socket) do
    handle_food_expense_event(updated_food_expense, socket)
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

  @impl true
  def handle_event(
        "move_note",
        %{"note_id" => note_id, "new_day_index" => new_day_index, "position" => position},
        socket
      ) do
    note = find_note_in_trip(note_id, socket.assigns.trip)
    new_day_index = ensure_int(new_day_index)
    position = ensure_int(position)

    case Planning.move_note_to_day(
           note,
           new_day_index,
           socket.assigns.trip,
           socket.assigns.current_user,
           position
         ) do
      {:ok, _updated_note} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(socket, :error, gettext("Failed to move note: %{reason}", reason: reason))

        Logger.error("Failed to move note: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "reorder_note",
        %{"note_id" => note_id, "position" => position},
        socket
      ) do
    note = find_note_in_trip(note_id, socket.assigns.trip)
    position = ensure_int(position)

    case Planning.reorder_note(note, position, socket.assigns.trip, socket.assigns.current_user) do
      {:ok, _updated_note} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(socket, :error, gettext("Failed to reorder note: %{reason}", reason: reason))

        Logger.error("Failed to reorder note: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "move_day_expense",
        %{
          "day_expense_id" => day_expense_id,
          "new_day_index" => new_day_index,
          "position" => position
        },
        socket
      ) do
    day_expense = find_day_expense_in_trip(day_expense_id, socket.assigns.trip)
    new_day_index = ensure_int(new_day_index)
    position = ensure_int(position)

    case Planning.move_day_expense_to_day(
           day_expense,
           new_day_index,
           socket.assigns.trip,
           socket.assigns.current_user,
           position
         ) do
      {:ok, _updated_day_expense} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(
            socket,
            :error,
            gettext("Failed to move expense: %{reason}", reason: reason)
          )

        Logger.error("Failed to move day expense: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "reorder_day_expense",
        %{"day_expense_id" => day_expense_id, "position" => position},
        socket
      ) do
    day_expense = find_day_expense_in_trip(day_expense_id, socket.assigns.trip)
    position = ensure_int(position)

    case Planning.reorder_day_expense(
           day_expense,
           position,
           socket.assigns.trip,
           socket.assigns.current_user
         ) do
      {:ok, _updated_day_expense} ->
        {:noreply, socket}

      {:error, reason} ->
        socket =
          put_flash(
            socket,
            :error,
            gettext("Failed to reorder expense: %{reason}", reason: reason)
          )

        Logger.error("Failed to reorder day expense: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  # COMPONENTS
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
      activities_outside={activities_outside(@trip)}
      notes={@trip.notes}
      notes_outside={notes_outside(@trip)}
      day_expenses={@trip.day_expenses}
      day_expenses_outside={day_expenses_outside(@trip)}
      budget={@budget}
      display_currency={@display_currency}
    />
    """
  end

  def render_tab(%{active_tab: "notes"} = assigns) do
    ~H"""
    <.tab_notes
      trip={@trip}
      notes={@trip.notes}
      notes_outside={notes_outside(@trip)}
    />
    """
  end

  attr(:trip, :map, required: true)
  attr(:active_tab, :string, required: true)
  attr(:class, :string, default: nil)

  def planning_tabs(assigns) do
    ~H"""
    <.tabs
      underline
      class={
        CoreComponents.build_class([
          "hidden sm:flex",
          @class
        ])
      }
    >
      <.tab
        underline
        to={trip_url(@trip.slug, :itinerary)}
        is_active={@active_tab == "itinerary"}
        link_type="live_patch"
      >
        <.inline>
          <.airplane />
          {gettext("Transfers and hotels")}
        </.inline>
      </.tab>
      <.tab
        underline
        to={trip_url(@trip.slug, :activities)}
        is_active={@active_tab == "activities"}
        link_type="live_patch"
      >
        <.inline>
          <.icon name="hero-ticket" class="h-5 w-5" />
          {gettext("Activities")}
        </.inline>
      </.tab>
      <.tab
        underline
        to={trip_url(@trip.slug, :notes)}
        is_active={@active_tab == "notes"}
        link_type="live_patch"
      >
        <.inline>
          <.icon name="hero-document-text" class="h-5 w-5" />
          {gettext("Notes")}
        </.inline>
      </.tab>
    </.tabs>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:notes, :list, required: true)
  attr(:notes_outside, :list, required: true)

  def tab_notes(assigns) do
    ~H"""
    <div id={"notes-#{@trip.id}"} phx-hook="ActivityDragDrop">
      <.toggle
        :if={Enum.any?(@notes_outside)}
        label={gettext("Some items are scheduled outside of the trip duration")}
        class="mt-4"
      >
        <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day="outside">
          <.notes_list notes={@notes_outside} day_index={-1} trip={@trip} />
        </div>
      </.toggle>

      <div class="flex flex-col gap-y-8 mt-8">
        <div class="flex flex-col gap-y-2">
          <.section_header icon="hero-document-text" label={gettext("Trip notes")} />
          <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day="unassigned">
            <.notes_list notes={Planning.notes_unassigned(@notes)} day_index={-1} trip={@trip} />
            <.live_component
              module={NoteNew}
              id="note-new-unassigned"
              trip={@trip}
              day_index={nil}
            />
          </div>
        </div>

        <div :for={i <- 0..(@trip.duration - 1)} class="flex flex-col gap-y-2">
          <div class="text-xl font-semibold">
            <.day_label day_index={i} start_date={@trip.start_date} />
          </div>
          <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day={i}>
            <.notes_list notes={Planning.notes_for_day(i, @notes)} day_index={i} trip={@trip} />
            <.live_component
              module={NoteNew}
              id={"note-new-#{i}"}
              trip={@trip}
              day_index={i}
            />
          </div>
          <hr />
        </div>
      </div>
    </div>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:budget, Money, required: true)
  attr(:display_currency, :string, required: true)
  attr(:destinations, :list, required: true)
  attr(:destinations_outside, :list, required: true)
  attr(:transfers, :list, required: true)
  attr(:transfers_outside, :list, required: true)
  attr(:accommodations, :list, required: true)
  attr(:accommodations_outside, :list, required: true)

  def tab_itinerary(assigns) do
    ~H"""
    <div phx-hook="TransferDragDrop" id="trip-itinerary">
      <.budget_display
        budget={@budget}
        display_currency={@display_currency}
        class="mt-4 sm:mt-8 text-xl"
      />

      <.toggle
        :if={
          Enum.any?(@destinations_outside) ||
            Enum.any?(@accommodations_outside) ||
            Enum.any?(@transfers_outside)
        }
        label={gettext("Some items are scheduled outside of the trip duration")}
        class="mt-4"
      >
        <.section_header icon="hero-map-pin" label={gettext("Places")} class="sm:hidden" />
        <.destinations_list trip={@trip} destinations={@destinations_outside} day_index={0} />

        <.section_header icon="hero-home" label={gettext("Hotel")} class="sm:hidden" />
        <.accommodations_list
          trip={@trip}
          accommodations={@accommodations_outside}
          display_currency={@display_currency}
          day_index={0}
        />

        <.section_header
          icon="hero-arrows-right-left"
          label={gettext("Transfers")}
          class="sm:hidden"
        />
        <div
          class="transfers-column min-h-0 sm:min-h-[100px] flex flex-col gap-y-1 sm:gap-y-8"
          data-transfer-drop-zone
          data-target-day="outside"
        >
          <.transfers_list
            trip={@trip}
            transfers={@transfers_outside}
            display_currency={@display_currency}
            day_index={-1}
          />
        </div>
      </.toggle>

      <table class="sm:mt-8 sm:table-auto sm:border-collapse sm:border sm:border-slate-500 sm:w-full">
        <thead>
          <tr class="hidden sm:table-row">
            <th class="border border-slate-600 px-2 py-4 text-left w-1/12">{gettext("Day")}</th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/6">
              {gettext("Places")}
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">
              {gettext("Transfers")}
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">{gettext("Hotel")}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={i <- 0..(@trip.duration - 1)}
            class="flex flex-col gap-y-1 mt-8 sm:table-row sm:gap-y-0 sm:mt-0"
          >
            <td class="text-xl font-bold sm:font-normal sm:text-base sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <.day_label day_index={i} start_date={@trip.start_date} />
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-1">
                <.section_header icon="hero-map-pin" label={gettext("Places")} class="sm:hidden" />
                <.destinations_list
                  trip={@trip}
                  destinations={Planning.destinations_for_day(i, @destinations)}
                  day_index={i}
                />
                <.live_component
                  module={DestinationNew}
                  id={"destination-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                />
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <.section_header
                icon="hero-arrows-right-left"
                label={gettext("Transfers")}
                class="sm:hidden"
              />
              <div
                class="transfers-column min-h-0 sm:min-h-[100px] flex flex-col gap-y-1"
                data-transfer-drop-zone
                data-target-day={i}
              >
                <.transfers_list
                  trip={@trip}
                  transfers={Planning.transfers_for_day(i, @transfers)}
                  display_currency={@display_currency}
                  day_index={i}
                />
                <.live_component
                  module={TransferNew}
                  id={"transfer-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                />
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-1">
                <.section_header icon="hero-home" label={gettext("Hotel")} class="sm:hidden" />
                <.accommodations_list
                  trip={@trip}
                  accommodations={Planning.accommodations_for_day(i, @accommodations)}
                  display_currency={@display_currency}
                  day_index={i}
                />
                <.live_component
                  module={AccommodationNew}
                  id={"accommodation-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:budget, Money, required: true)
  attr(:display_currency, :string, required: true)
  attr(:destinations, :list, required: true)
  attr(:destinations_outside, :list, required: true)
  attr(:activities, :list, required: true)
  attr(:activities_outside, :list, required: true)
  attr(:notes, :list, required: true)
  attr(:notes_outside, :list, required: true)
  attr(:day_expenses, :list, required: true)
  attr(:day_expenses_outside, :list, required: true)

  def tab_activity(assigns) do
    ~H"""
    <div id={"activities-#{@trip.id}"} phx-hook="ActivityDragDrop">
      <.budget_display
        budget={@budget}
        display_currency={@display_currency}
        class="mt-4 sm:mt-8 text-xl"
      />

      <.toggle
        :if={
          Enum.any?(@destinations_outside) || Enum.any?(@activities_outside) ||
            Enum.any?(@day_expenses_outside) || Enum.any?(@notes_outside)
        }
        label={gettext("Some items are scheduled outside of the trip duration")}
        class="mt-4"
      >
        <.section_header
          :if={Enum.any?(@destinations_outside)}
          icon="hero-map-pin"
          label={gettext("Places")}
        />
        <.destinations_list trip={@trip} destinations={@destinations_outside} day_index={0} />

        <div
          :if={
            Enum.any?(@activities_outside) ||
              Enum.any?(@day_expenses_outside) || Enum.any?(@notes_outside)
          }
          class="activities-column min-h-0 sm:min-h-[100px] flex flex-col gap-y-2 sm:gap-y-8"
        >
          <.section_header
            :if={Enum.any?(@day_expenses_outside)}
            icon="hero-banknotes"
            label={gettext("Expenses")}
          />
          <div
            :if={Enum.any?(@day_expenses_outside)}
            class="flex flex-col gap-y-1"
            data-day-expense-drop-zone
            data-target-day="outside"
          >
            <.day_expenses_list
              day_expenses={@day_expenses_outside}
              day_index={-1}
              trip={@trip}
              display_currency={@display_currency}
            />
          </div>
          <.section_header
            :if={Enum.any?(@activities_outside)}
            icon="hero-ticket"
            label={gettext("Activities")}
          />
          <div
            :if={Enum.any?(@activities_outside)}
            class="flex flex-col gap-y-1"
            data-activity-drop-zone
            data-target-day="outside"
          >
            <.activities_list
              activities={@activities_outside}
              day_index={-1}
              trip={@trip}
              display_currency={@display_currency}
            />
          </div>
          <.section_header
            :if={Enum.any?(@notes_outside)}
            icon="hero-document-text"
            label={gettext("Notes")}
          />
          <div :if={Enum.any?(@notes_outside)} class="flex flex-col gap-y-1">
            <.notes_list
              notes={@notes_outside}
              day_index={-1}
              trip={@trip}
            />
          </div>
        </div>
      </.toggle>

      <div :if={@trip.food_expense} class="mt-4">
        <.section_header icon="hero-shopping-cart" label={gettext("Food expenses")} />
        <div class="mt-3">
          <.live_component
            module={FoodExpense}
            id={"food-expense-#{@trip.food_expense.id}"}
            trip={@trip}
            food_expense={@trip.food_expense}
            display_currency={@display_currency}
          />
        </div>
      </div>

      <div class="flex flex-col gap-y-8 mt-8">
        <div :for={i <- 0..(@trip.duration - 1)} class="flex flex-col gap-y-2">
          <div class="text-xl font-semibold">
            <.day_label day_index={i} start_date={@trip.start_date} />
          </div>
          <.section_header icon="hero-map-pin" label={gettext("Places")} />
          <div class="flex flex-row gap-x-4">
            <.destinations_list
              trip={@trip}
              destinations={Planning.destinations_for_day(i, @destinations)}
              day_index={i}
            />
          </div>
          <div class="inline-block">
            <.live_component
              module={DestinationNew}
              id={"destination-new-#{i}"}
              trip={@trip}
              day_index={i}
              class="inline-block"
            />
          </div>

          <div class="flex flex-col gap-y-2 min-h-8">
            <.section_header icon="hero-banknotes" label={gettext("Expenses")} />
            <div class="flex flex-col gap-y-1" data-day-expense-drop-zone data-target-day={i}>
              <.day_expenses_list
                day_expenses={Planning.day_expenses_for_day(i, @day_expenses)}
                day_index={i}
                trip={@trip}
                display_currency={@display_currency}
              />
              <.live_component
                module={DayExpenseNew}
                id={"day-expense-new-#{i}"}
                trip={@trip}
                day_index={i}
              />
            </div>
            <.section_header icon="hero-ticket" label={gettext("Activities")} />
            <div class="flex flex-col gap-y-1" data-activity-drop-zone data-target-day={i}>
              <.activities_list
                activities={Planning.activities_for_day(i, @activities)}
                day_index={i}
                trip={@trip}
                display_currency={@display_currency}
              />
              <.live_component
                module={ActivityNew}
                id={"activity-new-#{i}"}
                trip={@trip}
                day_index={i}
              />
            </div>
            <.section_header icon="hero-document-text" label={gettext("Notes")} />
            <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day={i}>
              <.notes_list
                notes={Planning.notes_for_day(i, @notes)}
                day_index={i}
                trip={@trip}
              />
              <.live_component
                module={NoteNew}
                id={"note-new-#{i}"}
                trip={@trip}
                day_index={i}
              />
            </div>
          </div>
          <hr />
        </div>
      </div>
    </div>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:destinations, :list, required: true)
  attr(:day_index, :integer, required: true)

  def destinations_list(assigns) do
    ~H"""
    <.live_component
      :for={destination <- @destinations}
      module={Destination}
      id={"destination-#{destination.id}-day-#{@day_index}"}
      trip={@trip}
      destination={destination}
      day_index={@day_index}
    />
    """
  end

  attr(:start_date, Date, default: nil)
  attr(:day_index, :integer, required: true)

  def day_label(%{start_date: nil} = assigns) do
    ~H"""
    {gettext("Day")} {@day_index + 1}
    """
  end

  def day_label(assigns) do
    ~H"""
    {Formatter.date_with_weekday(Date.add(@start_date, @day_index))}
    """
  end

  attr(:trip, Trip, required: true)
  attr(:transfers, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:display_currency, :string, required: true)

  def transfers_list(assigns) do
    ~H"""
    <.live_component
      :for={transfer <- @transfers}
      module={Transfer}
      id={"transfer-#{transfer.id}-day-#{@day_index}"}
      trip={@trip}
      transfer={transfer}
      display_currency={@display_currency}
      day_index={@day_index}
    />
    """
  end

  attr(:trip, Trip, required: true)
  attr(:accommodations, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:display_currency, :string, required: true)

  def accommodations_list(assigns) do
    ~H"""
    <.live_component
      :for={accommodation <- @accommodations}
      module={Accommodation}
      id={"accommodation-#{accommodation.id}-day-#{@day_index}"}
      trip={@trip}
      accommodation={accommodation}
      display_currency={@display_currency}
      day_index={@day_index}
    />
    """
  end

  attr(:activities, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def activities_list(assigns) do
    ~H"""
    <.live_component
      :for={{activity, index} <- Enum.with_index(@activities)}
      module={Activity}
      id={"activities-#{activity.id}-day-#{@day_index}"}
      activity={activity}
      trip={@trip}
      display_currency={@display_currency}
      index={index}
    />
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:class, :string, default: nil)

  def section_header(assigns) do
    ~H"""
    <div class={
      CoreComponents.build_class([
        "border-t border-zinc-200/70 dark:border-zinc-700/70 pt-2 mt-3",
        @class
      ])
    }>
      <div class="text-xs font-semibold uppercase tracking-wide text-zinc-500">
        <.inline class="gap-1">
          <.icon name={@icon} class="h-4 w-4" />
          {@label}
        </.inline>
      </div>
    </div>
    """
  end

  attr(:day_expenses, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def day_expenses_list(assigns) do
    ~H"""
    <.live_component
      :for={day_expense <- @day_expenses}
      module={DayExpense}
      id={"day-expenses-#{day_expense.id}-day-#{@day_index}"}
      day_expense={day_expense}
      trip={@trip}
      display_currency={@display_currency}
    />
    """
  end

  attr(:trip, Trip, required: true)
  attr(:notes, :list, required: true)
  attr(:day_index, :integer, required: true)

  def notes_list(assigns) do
    ~H"""
    <.live_component
      :for={note <- @notes}
      module={Note}
      id={"note-#{note.id}-day-#{@day_index}"}
      trip={@trip}
      note={note}
    />
    """
  end

  # HELPERS

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

  defp activities_outside(trip) do
    trip.activities
    |> Enum.filter(fn activity ->
      activity.day_index >= trip.duration
    end)
  end

  defp day_expenses_outside(trip) do
    trip.day_expenses
    |> Enum.filter(fn day_expense ->
      day_expense.day_index >= trip.duration
    end)
  end

  defp notes_outside(trip) do
    trip.notes
    |> Enum.filter(fn note ->
      is_integer(note.day_index) && note.day_index >= trip.duration
    end)
  end

  defp get_key_for_component_adding_active_state_assign(component_type) do
    case component_type do
      "destination" -> :active_destination_adding_component_id
      "accommodation" -> :active_accommodation_adding_component_id
      "transfer" -> :active_transfer_adding_component_id
      "activity" -> :active_activity_adding_component_id
      "day-expense" -> :active_day_expense_adding_component_id
      "note" -> :active_note_adding_component_id
      _ -> raise ArgumentError, "Unsupported component type: #{component_type}"
    end
  end

  defp send_edit_state_to_entity_creation_components(socket, component_type) do
    case get_creation_component_info(component_type) do
      {module, active_assign_key} ->
        trip = socket.assigns.trip
        component_ids = creation_component_ids(component_type, trip.duration)

        Enum.each(component_ids, fn component_id ->
          send_update(module,
            id: component_id,
            edit: Map.get(socket.assigns, active_assign_key) == component_id
          )
        end)

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

      "day-expense" ->
        {HamsterTravelWeb.Planning.DayExpenseNew, :active_day_expense_adding_component_id}

      "note" ->
        {HamsterTravelWeb.Planning.NoteNew, :active_note_adding_component_id}

      _ ->
        nil
    end
  end

  defp creation_component_ids(component_type, duration) do
    base_ids = for i <- 0..(duration - 1), do: "#{component_type}-new-#{i}"

    base_ids ++ ["#{component_type}-new-unassigned"]
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

  defp handle_food_expense_event(food_expense, socket) do
    food_expense = Repo.preload(food_expense, [:expense])

    trip = %{socket.assigns.trip | food_expense: food_expense}

    socket =
      socket
      |> assign(trip: trip)
      |> assign(budget: Planning.calculate_budget(trip))

    {:noreply, socket}
  end

  defp preload_entity_associations(:destination, entity),
    do: Repo.preload(entity, city: Geo.city_preloading_query())

  defp preload_entity_associations(:accommodation, entity), do: Repo.preload(entity, [:expense])

  defp preload_entity_associations(:activity, entity), do: Repo.preload(entity, [:expense])
  defp preload_entity_associations(:day_expense, entity), do: Repo.preload(entity, [:expense])
  defp preload_entity_associations(:note, entity), do: entity

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
  defp get_entities_key(:day_expense), do: :day_expenses
  defp get_entities_key(:note), do: :notes
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

  defp maybe_recalculate_budget(socket, :day_expense, trip) do
    assign(socket, budget: Planning.calculate_budget(trip))
  end

  defp maybe_recalculate_budget(socket, _entity_type, _trip), do: socket

  defp find_transfer_in_trip(transfer_id, %Trip{transfers: transfers}) do
    Enum.find(transfers, &(Integer.to_string(&1.id) == transfer_id))
  end

  defp find_activity_in_trip(activity_id, %Trip{activities: activities}) do
    Enum.find(activities, &(Integer.to_string(&1.id) == activity_id))
  end

  defp find_day_expense_in_trip(day_expense_id, %Trip{day_expenses: day_expenses}) do
    Enum.find(day_expenses, &(Integer.to_string(&1.id) == day_expense_id))
  end

  defp find_note_in_trip(note_id, %Trip{notes: notes}) do
    Enum.find(notes, &(Integer.to_string(&1.id) == note_id))
  end

  defp ensure_int(val) when is_binary(val), do: String.to_integer(val)
  defp ensure_int(val), do: val
end
