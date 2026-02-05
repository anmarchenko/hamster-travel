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
  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Planning.TripCover
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
    Destination,
    DestinationNew,
    FoodExpense,
    Note,
    NoteNew,
    Transfer,
    TransferNew
  }

  @tabs ["itinerary", "activities", "notes"]
  @cover_upload_max_mb 8
  @cover_upload_max_file_size @cover_upload_max_mb * 1_000_000
  @cover_upload_accept ~w(.jpg .jpeg .png .webp)

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
            <.button
              :if={@can_edit}
              link_type="live_redirect"
              to={trip_url(@trip.slug, :edit)}
              color="secondary"
            >
              <.icon_text icon="hero-pencil" label={gettext("Edit")} />
            </.button>
            <.button
              :if={Policy.authorized?(:copy, @trip, @current_user)}
              link_type="live_redirect"
              to={trip_url(@trip.id, :copy)}
              color="secondary"
            >
              <.icon_text icon="hero-document-duplicate" label={gettext("Make a copy")} />
            </.button>
            <.button
              :if={Policy.authorized?(:delete, @trip, @current_user)}
              phx-click="delete_trip"
              data-confirm={gettext("Are you sure you want to delete this trip?")}
              color="danger"
            >
              <.icon_text icon="hero-trash" label={gettext("Delete")} />
            </.button>
          </.inline>
          <.status_row trip={@trip} />
        </div>
        <div class="sm:pl-6">
          <div class="flex flex-col items-end gap-3">
            <label
              :if={@trip.cover}
              for={@can_edit && @uploads.cover.ref}
              class={["cursor-pointer", !@can_edit && "pointer-events-none"]}
            >
              <img
                class="max-h-80 mb-4 sm:mb-0 sm:h-56 sm:w-auto sm:max-h-full shadow-lg rounded-md"
                src={TripCover.url({@trip.cover, @trip}, :hero)}
                data-cover-image
              />
            </label>
            <.cover_upload
              :if={@can_edit}
              trip={@trip}
              uploads={@uploads}
              cover_upload_errors={@cover_upload_errors}
            />
          </div>
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

    can_edit = can_edit?(trip, socket.assigns.current_user)

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
      |> assign(can_edit: can_edit)
      |> assign(cover_upload_errors: [])

    socket =
      allow_upload(socket, :cover,
        accept: @cover_upload_accept,
        max_entries: 1,
        max_file_size: @cover_upload_max_file_size,
        auto_upload: true,
        progress: &handle_progress/3
      )

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

  def handle_progress(:cover, entry, socket) do
    %{trip: trip, can_edit: can_edit, uploads: uploads} = socket.assigns
    entry_errors = upload_errors(uploads.cover, entry)

    if entry_errors != [] do
      socket =
        socket
        |> cancel_upload(:cover, entry.ref)
        |> assign(cover_upload_errors: Enum.uniq(entry_errors))

      {:noreply, socket}
    else
      if can_edit && entry.done? do
        {temp_path, entry} =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            {:ok, copy_upload_to_tmp(path, entry)}
          end)

        upload = %Plug.Upload{
          path: temp_path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        socket =
          case Planning.update_trip_cover(trip, upload) do
            {:ok, updated_trip} ->
              File.rm(temp_path)

              socket
              |> assign(trip: updated_trip)
              |> assign(cover_upload_errors: [])

            {:error, _error} ->
              File.rm(temp_path)

              socket
              |> assign(cover_upload_errors: [:upload_failed])
              |> put_flash(:error, gettext("Failed to update cover."))
          end

        {:noreply, socket}
      else
        {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("delete_outside_notes", _params, socket) do
    socket.assigns.trip
    |> notes_outside()
    |> Enum.each(&Planning.delete_note/1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_outside_itinerary", _params, socket) do
    trip = socket.assigns.trip

    trip
    |> destinations_outside()
    |> Enum.each(&Planning.delete_destination/1)

    trip
    |> accommodations_outside()
    |> Enum.each(&Planning.delete_accommodation/1)

    trip
    |> transfers_outside()
    |> Enum.each(&Planning.delete_transfer/1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_outside_activities", _params, socket) do
    trip = socket.assigns.trip

    trip
    |> destinations_outside()
    |> Enum.each(&Planning.delete_destination/1)

    trip
    |> activities_outside()
    |> Enum.each(&Planning.delete_activity/1)

    trip
    |> day_expenses_outside()
    |> Enum.each(&Planning.delete_day_expense/1)

    trip
    |> notes_outside()
    |> Enum.each(&Planning.delete_note/1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_trip", _params, socket) do
    %{trip: trip, current_user: user} = socket.assigns

    socket =
      if Policy.authorized?(:delete, trip, user) do
        case Planning.delete_trip(trip) do
          {:ok, _trip} ->
            socket
            |> put_flash(:info, gettext("Trip deleted."))
            |> push_navigate(to: ~p"/plans")

          {:error, _reason} ->
            put_flash(socket, :error, gettext("Failed to delete trip."))
        end
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_cover", _params, socket) do
    upload = socket.assigns.uploads.cover
    config_errors = upload_errors(upload)

    {socket, entry_errors} =
      Enum.reduce(upload.entries, {socket, []}, fn entry, {socket, errors} ->
        entry_errors = upload_errors(upload, entry)

        if entry_errors == [] do
          {socket, errors}
        else
          {cancel_upload(socket, :cover, entry.ref), errors ++ entry_errors}
        end
      end)

    errors = Enum.uniq(config_errors ++ entry_errors)

    {:noreply, assign(socket, cover_upload_errors: errors)}
  end

  @impl true
  def handle_event("remove_cover", _params, socket) do
    %{trip: trip, can_edit: can_edit} = socket.assigns

    if can_edit do
      socket =
        case Planning.update_trip(trip, %{cover: nil}) do
          {:ok, updated_trip} ->
            socket
            |> assign(trip: updated_trip)
            |> put_flash(:info, gettext("Cover removed."))

          {:error, _changeset} ->
            put_flash(socket, :error, gettext("Failed to remove cover."))
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
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
        <div class="flex justify-start mt-4">
          <.button
            color="danger"
            size="xs"
            phx-click="delete_outside_notes"
            data-confirm={gettext("Delete all notes scheduled outside this trip?")}
          >
            <.icon_text icon="hero-trash" label={gettext("Delete all")} />
          </.button>
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
        <.section_header
          :if={Enum.any?(@destinations_outside)}
          icon="hero-map-pin"
          label={gettext("Places")}
          class="mb-2"
        />
        <.destinations_list trip={@trip} destinations={@destinations_outside} day_index={0} />

        <.section_header
          :if={Enum.any?(@accommodations_outside)}
          icon="hero-home"
          label={gettext("Hotel")}
          class="mb-2"
        />
        <.accommodations_list
          trip={@trip}
          accommodations={@accommodations_outside}
          display_currency={@display_currency}
          day_index={0}
        />

        <.section_header
          :if={Enum.any?(@transfers_outside)}
          icon="hero-arrows-right-left"
          label={gettext("Transfers")}
          class="mb-2"
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
        <div class="flex justify-start mt-4">
          <.button
            color="danger"
            size="xs"
            phx-click="delete_outside_itinerary"
            data-confirm={
              gettext("Delete all places, hotels, and transfers scheduled outside this trip?")
            }
          >
            <.icon_text icon="hero-trash" label={gettext("Delete all")} />
          </.button>
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
                  destinations={Planning.items_for_day(i, @destinations)}
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
                  accommodations={Planning.items_for_day(i, @accommodations)}
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
          class="activities-column min-h-0 sm:min-h-[100px] flex flex-col gap-y-2"
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
        <div class="flex justify-start mt-4">
          <.button
            color="danger"
            size="xs"
            phx-click="delete_outside_activities"
            data-confirm={gettext("Delete all items scheduled outside this trip on this tab?")}
          >
            <.icon_text icon="hero-trash" label={gettext("Delete all")} />
          </.button>
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
              destinations={Planning.items_for_day(i, @destinations)}
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

  attr(:trip, Trip, required: true)
  attr(:uploads, :map, required: true)
  attr(:cover_upload_errors, :list, default: [])

  def cover_upload(assigns) do
    ~H"""
    <form id="cover-upload-form" phx-change="validate_cover" class="w-full sm:w-72">
      <div
        :if={is_nil(@trip.cover)}
        class="w-full rounded-xl border border-dashed border-zinc-200/80 bg-white/80 px-4 py-5 text-sm text-zinc-600 shadow-sm dark:border-zinc-700 dark:bg-zinc-900/40 dark:text-zinc-300"
        phx-drop-target={@uploads.cover.ref}
        data-cover-dropzone
      >
        <div class="flex flex-col gap-2">
          <span class="text-xs uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
            {gettext("Add cover")}
          </span>
          <span class="text-xs text-zinc-500 dark:text-zinc-400">
            {gettext("Drag and drop or choose a file.")}
          </span>
          <label
            for={@uploads.cover.ref}
            class="pc-button pc-button--secondary-light pc-button--xs pc-button--radius-md pc-button--with-icon w-fit cursor-pointer"
          >
            <.icon name="hero-arrow-up-tray" class="pc-button__spinner-icon--sm" />
            {gettext("Choose image")}
          </label>
        </div>
      </div>

      <div :if={@trip.cover} class="flex flex-wrap items-center gap-2 justify-end">
        <button
          type="button"
          class="group inline-flex items-center gap-1"
          phx-click="remove_cover"
          data-confirm={gettext("Remove the cover image?")}
        >
          <span class="inline-flex h-6 w-6 shrink-0 items-center justify-center text-zinc-500 transition-colors group-hover:text-zinc-700 dark:text-zinc-400 dark:group-hover:text-zinc-200">
            <.icon name="hero-trash" class="h-4 w-4" />
          </span>
          <span class="text-xs font-semibold text-zinc-500 dark:text-zinc-400 leading-4 transition-colors group-hover:text-zinc-700 dark:group-hover:text-zinc-200">
            {gettext("Remove cover")}
          </span>
        </button>
      </div>

      <.live_file_input upload={@uploads.cover} class="sr-only" />

      <div
        :for={entry <- @uploads.cover.entries}
        class="mt-3 text-xs text-zinc-500 dark:text-zinc-400"
      >
        <div class="flex items-center gap-2">
          <span class="font-semibold">{entry.client_name}</span>
          <progress value={entry.progress} max="100" class="h-1 w-32 accent-secondary-500" />
          <span>{entry.progress}%</span>
        </div>
        <p
          :for={err <- upload_errors(@uploads.cover, entry)}
          class="mt-1 text-xs font-semibold text-rose-600"
        >
          {cover_error(err)}
        </p>
      </div>

      <p
        :for={err <- @cover_upload_errors}
        class="mt-2 text-xs font-semibold text-rose-600"
      >
        {cover_error(err)}
      </p>

      <p
        :if={cover_uploading?(@uploads.cover)}
        class="mt-3 text-xs font-semibold text-zinc-500 dark:text-zinc-400"
      >
        {gettext("Uploading...")}
      </p>
    </form>
    """
  end

  # HELPERS

  defp active_nav(%{status: "0_draft"}), do: drafts_nav_item()
  defp active_nav(_), do: plans_nav_item()

  defp can_edit?(_trip, nil), do: false
  defp can_edit?(trip, user), do: Policy.authorized?(:edit, trip, user)

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

  defp cover_error(:too_large),
    do: gettext("File is too large. Maximum size is %{size} MB.", size: @cover_upload_max_mb)

  defp cover_error(:too_many_files), do: gettext("Only one image can be uploaded at a time.")
  defp cover_error(:not_accepted), do: gettext("Unsupported file type. Use JPG, PNG, or WebP.")
  defp cover_error(:upload_failed), do: gettext("Upload failed. Please try again.")
  defp cover_error(_), do: gettext("Upload failed. Please try again.")

  defp cover_uploading?(upload) do
    Enum.any?(upload.entries, fn entry ->
      not entry.done? and upload_errors(upload, entry) == []
    end)
  end

  defp copy_upload_to_tmp(path, entry) do
    extension = Path.extname(entry.client_name)
    filename = "trip-cover-#{entry.uuid}#{extension}"
    temp_path = Path.join(System.tmp_dir!(), filename)

    File.cp!(path, temp_path)

    {temp_path, entry}
  end
end
