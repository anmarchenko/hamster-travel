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
  alias HamsterTravel.Social
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
            <.button link_type="a" to={trip_url(@trip.slug, :export_pdf)} color="secondary">
              <.icon_text icon="hero-arrow-down-tray" label={gettext("Export to PDF")} />
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
          <.inline :if={@current_user} class="items-center gap-3 flex-wrap">
            <.status_row trip={@trip} class="gap-3" />
            <.trip_participants
              participants={@trip_participants}
              removable_participant_ids={@removable_participant_ids}
              can_add_participants={@can_add_participants}
            />
          </.inline>
          <.status_row :if={!@current_user} trip={@trip} />
        </div>
        <div class="sm:pl-6">
          <div class="flex flex-col items-end gap-3">
            <label
              :if={TripCover.present?(@trip.cover)}
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
        current_user={@current_user}
        can_edit={@can_edit}
      />
    </.container>

    <.modal
      :if={@show_invite_participant_modal}
      id="trip-invite-participant-modal"
      show
      on_cancel={JS.push("close_invite_participant_modal")}
    >
      <.invite_participant_modal available_participants={@available_participants} />
    </.modal>

    <.modal
      :if={@show_reorder_days_modal}
      id="trip-reorder-days-modal"
      show
      max_width_class="max-w-[95vw]"
      on_cancel={JS.push("close_reorder_days_modal")}
    >
      <.reorder_days_modal trip={@trip} />
    </.modal>
    """
  end

  # EVENT HANDLERS

  @impl true
  def mount(%{"trip_slug" => slug} = params, _session, socket) do
    trip = Planning.fetch_trip!(slug, socket.assigns.current_user)
    display_currency = socket.assigns.current_user.default_currency || "EUR"

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
      |> assign(display_currency: display_currency)
      |> assign(active_destination_adding_component_id: nil)
      |> assign(active_accommodation_adding_component_id: nil)
      |> assign(active_transfer_adding_component_id: nil)
      |> assign(active_activity_adding_component_id: nil)
      |> assign(active_day_expense_adding_component_id: nil)
      |> assign(active_note_adding_component_id: nil)
      |> assign(cover_upload_errors: [])
      |> assign(show_invite_participant_modal: false)
      |> assign(show_reorder_days_modal: false)
      |> assign_trip_state(trip)

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
  def handle_info({[:expense, :created], %{value: _created_expense}}, socket) do
    handle_expense_event(socket)
  end

  @impl true
  def handle_info({[:expense, :updated], %{value: _updated_expense}}, socket) do
    handle_expense_event(socket)
  end

  @impl true
  def handle_info({[:expense, :deleted], %{value: _deleted_expense}}, socket) do
    handle_expense_event(socket)
  end

  @impl true
  def handle_info({[:food_expense, :updated], %{value: updated_food_expense}}, socket) do
    handle_food_expense_event(updated_food_expense, socket)
  end

  @impl true
  def handle_info({[:trip, :updated], %{value: updated_trip}}, socket) do
    {:noreply, assign_trip_state(socket, updated_trip)}
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
              |> assign_trip_state(updated_trip)
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
    if socket.assigns.can_edit do
      socket.assigns.trip
      |> notes_outside()
      |> Enum.each(&Planning.delete_note/1)

      {:noreply, socket}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("delete_outside_itinerary", _params, socket) do
    if socket.assigns.can_edit do
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
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("delete_outside_activities", _params, socket) do
    if socket.assigns.can_edit do
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
    else
      {:noreply, unauthorized_edit(socket)}
    end
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
            |> assign_trip_state(updated_trip)
            |> put_flash(:info, gettext("Cover removed."))

          {:error, _changeset} ->
            put_flash(socket, :error, gettext("Failed to remove cover."))
        end

      {:noreply, socket}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("open_invite_participant_modal", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :show_invite_participant_modal, true)}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("close_invite_participant_modal", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :show_invite_participant_modal, false)}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("open_reorder_days_modal", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :show_reorder_days_modal, true)}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("close_reorder_days_modal", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :show_reorder_days_modal, false)}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event(
        "move_day",
        %{"from_day_index" => from_day_index, "to_day_index" => to_day_index},
        socket
      ) do
    if socket.assigns.can_edit do
      from_day_index = ensure_int(from_day_index)
      to_day_index = ensure_int(to_day_index)

      case Planning.move_trip_day(
             socket.assigns.trip,
             from_day_index,
             to_day_index,
             socket.assigns.current_user
           ) do
        {:ok, updated_trip} ->
          {:noreply, assign_trip_state(socket, updated_trip)}

        {:error, reason} ->
          reason_text = if is_binary(reason), do: reason, else: inspect(reason)

          socket =
            put_flash(
              socket,
              :error,
              gettext("Failed to move day: %{reason}", reason: reason_text)
            )

          Logger.error("Failed to move day: #{inspect(reason)}")

          {:noreply, socket}
      end
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("quick_add_trip_participant", %{"user_id" => participant_id}, socket)
      when participant_id in [nil, ""] do
    if socket.assigns.can_edit do
      {:noreply, put_flash(socket, :error, gettext("Please choose a friend."))}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("quick_add_trip_participant", %{"user_id" => participant_id}, socket) do
    if socket.assigns.can_edit do
      {:noreply, add_trip_participant_to_socket(socket, participant_id)}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event(
        "add_trip_participant",
        %{"participant" => %{"user_id" => participant_id}},
        socket
      )
      when participant_id in [nil, ""] do
    if socket.assigns.can_edit do
      {:noreply, put_flash(socket, :error, gettext("Please choose a friend."))}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event(
        "add_trip_participant",
        %{"participant" => %{"user_id" => participant_id}},
        socket
      ) do
    if socket.assigns.can_edit do
      {:noreply, add_trip_participant_to_socket(socket, participant_id)}
    else
      {:noreply, unauthorized_edit(socket)}
    end
  end

  @impl true
  def handle_event("remove_trip_participant", %{"user_id" => participant_id}, socket) do
    %{trip: trip, current_user: current_user} = socket.assigns

    socket =
      case Planning.remove_trip_participant(trip, current_user, participant_id) do
        {:ok, updated_trip} ->
          socket
          |> assign_trip_state(updated_trip)
          |> put_flash(:info, gettext("Participant removed."))

        {:error, :cannot_remove_author} ->
          put_flash(socket, :error, gettext("The trip author cannot be removed."))

        {:error, :not_allowed} ->
          put_flash(socket, :error, gettext("You are not allowed to remove this participant."))

        {:error, :not_found} ->
          put_flash(socket, :error, gettext("Participant not found."))

        {:error, _reason} ->
          put_flash(socket, :error, gettext("Failed to remove participant."))
      end

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
      current_user={@current_user}
      can_edit={@can_edit}
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
      can_edit={@can_edit}
    />
    """
  end

  def render_tab(%{active_tab: "notes"} = assigns) do
    ~H"""
    <.tab_notes
      trip={@trip}
      notes={@trip.notes}
      notes_outside={notes_outside(@trip)}
      can_edit={@can_edit}
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
  attr(:can_edit, :boolean, required: true)

  def tab_notes(assigns) do
    ~H"""
    <div id={"notes-#{@trip.id}"} phx-hook="ActivityDragDrop">
      <.toggle
        :if={Enum.any?(@notes_outside)}
        label={gettext("Some items are scheduled outside of the trip duration")}
        class="mt-4"
      >
        <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day="outside">
          <.notes_list notes={@notes_outside} day_index={-1} trip={@trip} can_edit={@can_edit} />
        </div>
        <div :if={@can_edit} class="flex justify-start mt-4">
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
            <.notes_list
              notes={Planning.notes_unassigned(@notes)}
              day_index={-1}
              trip={@trip}
              can_edit={@can_edit}
            />
            <.live_component
              :if={@can_edit}
              module={NoteNew}
              id="note-new-unassigned"
              trip={@trip}
              day_index={nil}
              can_edit={@can_edit}
            />
          </div>
        </div>

        <div :for={i <- 0..(@trip.duration - 1)} class="flex flex-col gap-y-2">
          <div class="text-xl font-semibold">
            <.day_label day_index={i} start_date={@trip.start_date} />
          </div>
          <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day={i}>
            <.notes_list
              notes={Planning.notes_for_day(i, @notes)}
              day_index={i}
              trip={@trip}
              can_edit={@can_edit}
            />
            <.live_component
              :if={@can_edit}
              module={NoteNew}
              id={"note-new-#{i}"}
              trip={@trip}
              day_index={i}
              can_edit={@can_edit}
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
  attr(:current_user, HamsterTravel.Accounts.User, default: nil)
  attr(:can_edit, :boolean, required: true)

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
        <.destinations_list
          trip={@trip}
          destinations={@destinations_outside}
          day_index={0}
          can_edit={@can_edit}
        />

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
          can_edit={@can_edit}
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
            current_user={@current_user}
            display_currency={@display_currency}
            day_index={-1}
            can_edit={@can_edit}
          />
        </div>
        <div :if={@can_edit} class="flex justify-start mt-4">
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
              <div class="flex flex-col items-start gap-y-2">
                <.day_label day_index={i} start_date={@trip.start_date} />
                <button
                  :if={@can_edit && @trip.duration > 1}
                  id={"open-reorder-days-#{i}"}
                  type="button"
                  phx-click="open_reorder_days_modal"
                  class="hidden sm:inline-block text-sm font-normal underline text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
                >
                  {gettext("Move")}
                </button>
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-1">
                <.section_header icon="hero-map-pin" label={gettext("Places")} class="sm:hidden" />
                <.destinations_list
                  trip={@trip}
                  destinations={Planning.items_for_day(i, @destinations)}
                  day_index={i}
                  can_edit={@can_edit}
                />
                <.live_component
                  :if={@can_edit}
                  module={DestinationNew}
                  id={"destination-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                  can_edit={@can_edit}
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
                  current_user={@current_user}
                  display_currency={@display_currency}
                  day_index={i}
                  can_edit={@can_edit}
                />
                <.live_component
                  :if={@can_edit}
                  module={TransferNew}
                  id={"transfer-new-#{i}"}
                  trip={@trip}
                  current_user={@current_user}
                  day_index={i}
                  can_edit={@can_edit}
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
                  can_edit={@can_edit}
                />
                <.live_component
                  :if={@can_edit}
                  module={AccommodationNew}
                  id={"accommodation-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                  can_edit={@can_edit}
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
  attr(:can_edit, :boolean, required: true)

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
        <.destinations_list
          trip={@trip}
          destinations={@destinations_outside}
          day_index={0}
          can_edit={@can_edit}
        />

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
              can_edit={@can_edit}
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
              can_edit={@can_edit}
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
              can_edit={@can_edit}
            />
          </div>
        </div>
        <div :if={@can_edit} class="flex justify-start mt-4">
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
            can_edit={@can_edit}
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
              can_edit={@can_edit}
            />
          </div>
          <div :if={@can_edit} class="inline-block">
            <.live_component
              module={DestinationNew}
              id={"destination-new-#{i}"}
              trip={@trip}
              day_index={i}
              class="inline-block"
              can_edit={@can_edit}
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
                can_edit={@can_edit}
              />
              <.live_component
                :if={@can_edit}
                module={DayExpenseNew}
                id={"day-expense-new-#{i}"}
                trip={@trip}
                day_index={i}
                can_edit={@can_edit}
              />
            </div>
            <.section_header icon="hero-ticket" label={gettext("Activities")} />
            <div class="flex flex-col gap-y-1" data-activity-drop-zone data-target-day={i}>
              <.activities_list
                activities={Planning.activities_for_day(i, @activities)}
                day_index={i}
                trip={@trip}
                display_currency={@display_currency}
                can_edit={@can_edit}
              />
              <.live_component
                :if={@can_edit}
                module={ActivityNew}
                id={"activity-new-#{i}"}
                trip={@trip}
                day_index={i}
                can_edit={@can_edit}
              />
            </div>
            <.section_header icon="hero-document-text" label={gettext("Notes")} />
            <div class="flex flex-col gap-y-1" data-note-drop-zone data-target-day={i}>
              <.notes_list
                notes={Planning.notes_for_day(i, @notes)}
                day_index={i}
                trip={@trip}
                can_edit={@can_edit}
              />
              <.live_component
                :if={@can_edit}
                module={NoteNew}
                id={"note-new-#{i}"}
                trip={@trip}
                day_index={i}
                can_edit={@can_edit}
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
  attr(:can_edit, :boolean, required: true)

  def destinations_list(assigns) do
    ~H"""
    <.live_component
      :for={destination <- @destinations}
      module={Destination}
      id={"destination-#{destination.id}-day-#{@day_index}"}
      trip={@trip}
      destination={destination}
      day_index={@day_index}
      can_edit={@can_edit}
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
  attr(:current_user, HamsterTravel.Accounts.User, default: nil)
  attr(:day_index, :integer, required: true)
  attr(:display_currency, :string, required: true)
  attr(:can_edit, :boolean, required: true)

  def transfers_list(assigns) do
    ~H"""
    <.live_component
      :for={transfer <- @transfers}
      module={Transfer}
      id={"transfer-#{transfer.id}-day-#{@day_index}"}
      trip={@trip}
      transfer={transfer}
      current_user={@current_user}
      display_currency={@display_currency}
      day_index={@day_index}
      can_edit={@can_edit}
    />
    """
  end

  attr(:trip, Trip, required: true)
  attr(:accommodations, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:display_currency, :string, required: true)
  attr(:can_edit, :boolean, required: true)

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
      can_edit={@can_edit}
    />
    """
  end

  attr(:activities, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)
  attr(:can_edit, :boolean, required: true)

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
      can_edit={@can_edit}
    />
    """
  end

  attr(:day_expenses, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)
  attr(:can_edit, :boolean, required: true)

  def day_expenses_list(assigns) do
    ~H"""
    <.live_component
      :for={day_expense <- @day_expenses}
      module={DayExpense}
      id={"day-expenses-#{day_expense.id}-day-#{@day_index}"}
      day_expense={day_expense}
      trip={@trip}
      display_currency={@display_currency}
      can_edit={@can_edit}
    />
    """
  end

  attr(:trip, Trip, required: true)
  attr(:notes, :list, required: true)
  attr(:day_index, :integer, required: true)
  attr(:can_edit, :boolean, required: true)

  def notes_list(assigns) do
    ~H"""
    <.live_component
      :for={note <- @notes}
      module={Note}
      id={"note-#{note.id}-day-#{@day_index}"}
      trip={@trip}
      note={note}
      can_edit={@can_edit}
    />
    """
  end

  attr(:trip, Trip, required: true)

  def reorder_days_modal(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-6xl">
      <h3 class="text-2xl font-semibold text-zinc-900 dark:text-zinc-100">
        {gettext("Change day order")}
      </h3>

      <p class="mt-2 text-sm text-zinc-600 dark:text-zinc-300">
        {gettext(
          "All places, transfers, hotels, activities, expenses, and notes will be moved together."
        )}
      </p>

      <div class="mt-6 overflow-x-auto">
        <div class="min-w-[920px] rounded-lg border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-900">
          <div class="grid grid-cols-[84px_180px_1fr_1fr_1fr_1fr] gap-x-4 border-b border-zinc-200 px-4 py-3 text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
            <div>{gettext("Move")}</div>
            <div>{gettext("Day")}</div>
            <div>{gettext("Places")}</div>
            <div>{gettext("Transfers")}</div>
            <div>{gettext("Activities")}</div>
            <div>{gettext("Expenses and notes")}</div>
          </div>

          <div
            :for={day_index <- 0..(@trip.duration - 1)}
            class="grid grid-cols-[84px_180px_1fr_1fr_1fr_1fr] gap-x-4 border-b border-zinc-100 px-4 py-3 text-sm last:border-b-0 dark:border-zinc-800"
          >
            <div class="flex items-center gap-1">
              <button
                id={"move-day-up-#{day_index}"}
                type="button"
                phx-click="move_day"
                phx-value-from_day_index={day_index}
                phx-value-to_day_index={day_index - 1}
                disabled={day_index == 0}
                class="inline-flex h-8 w-8 items-center justify-center rounded-md border border-zinc-300 text-zinc-600 disabled:cursor-not-allowed disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
                aria-label={gettext("Move day up")}
              >
                <.icon name="hero-chevron-up" class="h-4 w-4" />
              </button>
              <button
                id={"move-day-down-#{day_index}"}
                type="button"
                phx-click="move_day"
                phx-value-from_day_index={day_index}
                phx-value-to_day_index={day_index + 1}
                disabled={day_index == @trip.duration - 1}
                class="inline-flex h-8 w-8 items-center justify-center rounded-md border border-zinc-300 text-zinc-600 disabled:cursor-not-allowed disabled:opacity-40 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
                aria-label={gettext("Move day down")}
              >
                <.icon name="hero-chevron-down" class="h-4 w-4" />
              </button>
            </div>
            <div class="font-medium text-zinc-900 dark:text-zinc-100">
              <.day_label day_index={day_index} start_date={@trip.start_date} />
            </div>
            <div class="text-zinc-700 dark:text-zinc-300">
              {reorder_day_places_summary(@trip, day_index)}
            </div>
            <div class="text-zinc-700 dark:text-zinc-300">
              {reorder_day_transfers_summary(@trip, day_index)}
            </div>
            <div class="text-zinc-700 dark:text-zinc-300">
              {reorder_day_activities_summary(@trip, day_index)}
            </div>
            <div class="text-zinc-700 dark:text-zinc-300">
              {reorder_day_other_summary(@trip, day_index)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:uploads, :map, required: true)
  attr(:cover_upload_errors, :list, default: [])

  def cover_upload(assigns) do
    ~H"""
    <form id="cover-upload-form" phx-change="validate_cover" class="w-full sm:w-72">
      <div
        :if={!TripCover.present?(@trip.cover)}
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

      <div :if={TripCover.present?(@trip.cover)} class="flex flex-wrap items-center gap-2 justify-end">
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

  attr(:participants, :list, required: true)
  attr(:removable_participant_ids, :list, default: [])
  attr(:can_add_participants, :boolean, default: false)
  attr(:class, :string, default: nil)

  def trip_participants(assigns) do
    ~H"""
    <div id="trip-participants" class={["flex flex-wrap items-center gap-3", @class]}>
      <div
        :for={participant <- @participants}
        id={"trip-participant-#{participant.id}"}
        class="group relative h-9 w-9 shrink-0"
      >
        <.avatar
          size="sm"
          src={participant.avatar_url}
          name={participant.name}
          random_color
          class="h-9! w-9! ring-2 ring-white dark:ring-zinc-900"
        />
        <button
          :if={participant.id in @removable_participant_ids}
          type="button"
          phx-click="remove_trip_participant"
          phx-value-user_id={participant.id}
          data-confirm={gettext("Remove this participant from the trip?")}
          class="absolute z-10 inline-flex h-5 w-5 items-center justify-center rounded-full border border-zinc-300 bg-zinc-100 text-zinc-500 shadow-md transition-colors hover:bg-zinc-200 hover:text-zinc-700 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-700"
          style="right: -0.5rem; top: -0.25rem;"
          aria-label={gettext("Remove participant")}
        >
          <.icon name="hero-trash" class="h-3 w-3" />
        </button>
      </div>

      <div
        :if={@can_add_participants}
        id="trip-add-participant"
        class="relative"
      >
        <button
          id="trip-open-invite-modal"
          type="button"
          phx-click="open_invite_participant_modal"
          class="group inline-flex h-8 w-8 items-center justify-center rounded-full border border-zinc-300 bg-white text-zinc-600 shadow-sm transition-all hover:shadow-md dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-300"
          aria-label={gettext("Invite friend")}
        >
          <.icon name="hero-plus" class="h-5 w-5" />
        </button>
      </div>
    </div>
    """
  end

  attr(:available_participants, :list, default: [])

  def invite_participant_modal(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-2xl" x-data="{ search: '' }">
      <div class="space-y-4">
        <div class="text-xl sm:text-2xl font-semibold tracking-tight text-zinc-900 dark:text-zinc-100">
          {gettext("Invite friend")}
        </div>

        <div class="text-sm font-medium text-zinc-600 dark:text-zinc-300">
          {gettext("Select from friends")}
        </div>

        <div>
          <input
            type="text"
            x-model="search"
            placeholder={gettext("Search and select friends...")}
            class="h-11 w-full rounded-xl border border-zinc-300 bg-white px-3 text-base text-zinc-700 shadow-sm outline-none transition focus:border-secondary-500 focus:ring-2 focus:ring-secondary-200 dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-200 dark:focus:ring-secondary-900"
          />
        </div>

        <div class="max-h-64 overflow-y-auto rounded-xl border border-zinc-200 bg-white p-1 dark:border-zinc-700 dark:bg-zinc-900">
          <button
            :for={friend <- @available_participants}
            id={"trip-invite-friend-#{friend.id}"}
            type="button"
            phx-click="quick_add_trip_participant"
            phx-value-user_id={friend.id}
            data-name={String.downcase(friend.name)}
            x-show="$el.dataset.name.includes(search.toLowerCase())"
            class="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left transition-colors hover:bg-zinc-50 dark:hover:bg-zinc-800"
          >
            <.avatar
              size="sm"
              src={friend.avatar_url}
              name={friend.name}
              random_color
              class="h-8! w-8!"
            />
            <span class="grow text-base leading-tight text-zinc-900 dark:text-zinc-100">
              {friend.name}
            </span>
          </button>
        </div>
      </div>
    </div>
    """
  end

  # HELPERS

  defp reorder_day_places_summary(trip, day_index) do
    Planning.items_for_day(day_index, trip.destinations)
    |> Enum.map(&Geo.city_name(&1.city))
    |> Enum.uniq()
    |> join_with_fallback(gettext("No places"))
  end

  defp reorder_day_transfers_summary(trip, day_index) do
    Planning.transfers_for_day(day_index, trip.transfers)
    |> Enum.map(&transfer_route_summary/1)
    |> join_with_fallback(gettext("No transfers"))
  end

  defp reorder_day_activities_summary(trip, day_index) do
    Planning.activities_for_day(day_index, trip.activities)
    |> Enum.map(& &1.name)
    |> join_with_fallback(gettext("No activities"))
  end

  defp reorder_day_other_summary(trip, day_index) do
    day_expense_names =
      Planning.day_expenses_for_day(day_index, trip.day_expenses)
      |> Enum.map(& &1.name)

    note_titles =
      Planning.notes_for_day(day_index, trip.notes)
      |> Enum.map(& &1.title)

    (day_expense_names ++ note_titles)
    |> join_with_fallback(gettext("No expenses or notes"))
  end

  defp transfer_route_summary(transfer) do
    "#{Geo.city_name(transfer.departure_city)} - #{Geo.city_name(transfer.arrival_city)}"
  end

  defp join_with_fallback([], fallback), do: fallback
  defp join_with_fallback(values, _fallback), do: Enum.join(values, ", ")

  defp active_nav(%{status: "0_draft"}), do: drafts_nav_item()
  defp active_nav(_), do: plans_nav_item()

  defp add_trip_participant_to_socket(socket, participant_id) do
    %{trip: trip, current_user: current_user} = socket.assigns

    case Planning.add_trip_participant(trip, current_user, participant_id) do
      {:ok, updated_trip} ->
        socket
        |> assign_trip_state(updated_trip)
        |> assign(show_invite_participant_modal: false)
        |> put_flash(:info, gettext("Participant added."))

      {:error, :already_participant} ->
        put_flash(socket, :error, gettext("This user is already participating in the trip."))

      {:error, :not_in_author_friend_circle} ->
        put_flash(socket, :error, gettext("Only author's friends can be added to this trip."))

      {:error, :author_cannot_be_added} ->
        put_flash(socket, :error, gettext("The trip author is always a participant."))

      {:error, :not_participant} ->
        put_flash(socket, :error, gettext("Only trip participants can add participants."))

      {:error, :user_not_found} ->
        put_flash(socket, :error, gettext("User not found."))

      {:error, _reason} ->
        put_flash(socket, :error, gettext("Failed to add participant."))
    end
  end

  defp unauthorized_edit(socket) do
    put_flash(socket, :error, gettext("Only trip participants can edit this trip."))
  end

  defp can_edit?(_trip, nil), do: false
  defp can_edit?(trip, user), do: Policy.authorized?(:edit, trip, user)

  defp assign_trip_state(socket, %Trip{} = trip) do
    current_user = socket.assigns.current_user
    participants = trip_participant_users(trip)
    removable_participant_ids = removable_participant_ids(trip, current_user)
    available_participants = available_participants(trip)

    can_add_participants =
      can_add_participants?(trip, current_user, available_participants)

    socket
    |> assign(trip: trip)
    |> assign(budget: Planning.calculate_budget(trip))
    |> assign(can_edit: can_edit?(trip, current_user))
    |> assign(trip_participants: participants)
    |> assign(removable_participant_ids: removable_participant_ids)
    |> assign(can_add_participants: can_add_participants)
    |> assign(available_participants: available_participants)
  end

  defp trip_participant_users(%Trip{} = trip) do
    trip_participants =
      case trip.trip_participants do
        participants when is_list(participants) -> participants
        _ -> []
      end

    trip_participants
    |> Enum.map(& &1.user)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(&(to_string(&1.name) |> String.downcase()))
  end

  defp available_participants(%Trip{} = trip) do
    participant_ids =
      trip
      |> trip_participant_users()
      |> Enum.map(& &1.id)
      |> MapSet.new()

    trip.author_id
    |> Social.list_friends()
    |> Enum.reject(&MapSet.member?(participant_ids, &1.id))
  end

  defp can_add_participants?(_trip, nil, _available_participants), do: false

  defp can_add_participants?(trip, current_user, available_participants) do
    available_participants != [] and Policy.participant?(trip, current_user)
  end

  defp removable_participant_ids(%Trip{}, nil), do: []

  defp removable_participant_ids(%Trip{} = trip, current_user) do
    participant_ids = Enum.map(trip.trip_participants, & &1.user_id)

    cond do
      current_user.id == trip.author_id ->
        participant_ids

      current_user.id in participant_ids ->
        [current_user.id]

      true ->
        []
    end
  end

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

    # Recalculate budget if the changed entity has an expense attached
    socket =
      socket
      |> assign(trip: trip)
      |> maybe_recalculate_budget(entity_type, trip)

    {:noreply, socket}
  end

  defp handle_expense_event(socket) do
    socket =
      socket
      |> assign(budget: budget_from_db(socket.assigns.trip))

    {:noreply, socket}
  end

  defp handle_food_expense_event(food_expense, socket) do
    food_expense = Repo.preload(food_expense, [:expense])

    trip = Map.put(socket.assigns.trip, :food_expense, food_expense)

    socket =
      socket
      |> assign(trip: trip)
      |> assign(budget: budget_from_db(trip))

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

  defp budget_from_db(trip) do
    trip
    |> Map.put(:expenses, Planning.list_expenses(trip))
    |> Planning.calculate_budget()
  end

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
    assign(socket, budget: budget_from_db(trip))
  end

  defp maybe_recalculate_budget(socket, :transfer, trip) do
    assign(socket, budget: budget_from_db(trip))
  end

  defp maybe_recalculate_budget(socket, :activity, trip) do
    assign(socket, budget: budget_from_db(trip))
  end

  defp maybe_recalculate_budget(socket, :day_expense, trip) do
    assign(socket, budget: budget_from_db(trip))
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
