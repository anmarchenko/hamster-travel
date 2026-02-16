defmodule HamsterTravelWeb.Planning.TripForm do
  @moduledoc """
  Trip create/edit form
  """

  use HamsterTravelWeb, :live_component

  alias Ecto.Changeset

  alias HamsterTravel.Dates
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip

  alias HamsterTravelWeb.Cldr

  @impl true
  def update(assigns, socket) do
    changeset =
      case assigns.action do
        :new ->
          cond do
            assigns[:copy_from] ->
              Planning.new_trip(assigns.copy_from)

            assigns[:is_draft] ->
              Planning.new_trip(%{status: Trip.draft(), dates_unknown: true, duration: 1})

            true ->
              Planning.new_trip(%{status: Trip.planned()})
          end

        :edit ->
          Planning.change_trip(assigns.trip)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:dates_unknown, Changeset.get_field(changeset, :dates_unknown))
      |> assign(:start_date, Changeset.get_field(changeset, :start_date))
      |> assign(:end_date, Changeset.get_field(changeset, :end_date))
      |> assign(:status, Changeset.get_field(changeset, :status))
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:selected_duration, selected_duration(assigns.form))

    ~H"""
    <div>
      <.form_container>
        <.form
          id="trip-form"
          for={@form}
          as={:trip}
          phx-submit="form_submit"
          phx-change="form_changed"
          phx-target={@myself}
        >
          <div class="grid grid-cols-6 gap-x-6">
            <div class="col-span-6">
              <.field
                type="text"
                field={@form[:name]}
                label={gettext("Trip name")}
                required={true}
                autofocus={true}
              />
            </div>
            <div class="col-span-6">
              <.field
                field={@form[:status]}
                label={gettext("Trip status")}
                type="select"
                options={
                  for status <- Trip.statuses(),
                      do: {Gettext.gettext(HamsterTravelWeb.Gettext, status), status}
                }
              />
            </div>
            <div class="col-span-6">
              <.field
                type="select"
                field={@form[:currency]}
                options={Cldr.all_currencies()}
                label={gettext("Trip currency")}
                required={true}
              />
            </div>
            <div class="col-span-6">
              <.field
                :if={@status != Trip.finished()}
                type="checkbox"
                field={@form[:dates_unknown]}
                label={gettext("Dates are yet unknown")}
              />
            </div>
            <div :if={!@dates_unknown} class="col-span-6">
              <.date_range_field
                id="trip-dates"
                label={gettext("Trip dates")}
                locale={@current_user.locale}
                start_date_field={@form[:start_date]}
                end_date_field={@form[:end_date]}
                required={true}
                hint={
                  if @selected_duration > 0 do
                    "#{gettext("Duration")}: #{@selected_duration} #{ngettext("day", "days", @selected_duration)}"
                  end
                }
              />
            </div>
            <div :if={@dates_unknown} class="col-span-6">
              <.field
                type="number"
                field={@form[:duration]}
                label={gettext("Duration")}
                required={true}
              />
            </div>
            <div class="col-span-6">
              <.field
                type="number"
                field={@form[:people_count]}
                label={gettext("People count")}
                required={true}
              />
            </div>
            <div class="col-span-6">
              <.field type="checkbox" field={@form[:private]} label={gettext("Private trip")} />
            </div>
          </div>

          <div class="flex justify-between">
            <.button link_type="live_redirect" to={@back_url} color="white">
              {gettext("Cancel")}
            </.button>
            <.button color="primary">
              {gettext("Save")}
            </.button>
          </div>
        </.form>
      </.form_container>
    </div>
    """
  end

  @impl true
  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "dates_unknown"],
          "trip" => %{"dates_unknown" => dates_unknown} = trip_params
        },
        %{assigns: assigns} = socket
      ) do
    # convert dates_unknown to boolean
    dates_unknown = dates_unknown == "true"

    trip_params =
      trip_params
      |> Map.merge(%{
        "start_date" => assigns.start_date,
        "end_date" => assigns.end_date,
        "duration" => Dates.duration(assigns.start_date, assigns.end_date)
      })

    {:noreply,
     socket
     |> assign(:dates_unknown, dates_unknown)
     |> assign_form(trip_params)}
  end

  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "start_date"],
          "trip" => %{"start_date" => start_date} = trip_params
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(start_date: start_date)
     |> assign_form(trip_params)}
  end

  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "end_date"],
          "trip" => %{"end_date" => end_date} = trip_params
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(end_date: end_date)
     |> assign_form(trip_params)}
  end

  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "status"],
          "trip" => %{"status" => status} = trip_params
        },
        socket
      ) do
    socket =
      if status == Trip.finished() do
        socket
        |> assign(:dates_unknown, false)
      else
        socket
      end

    trip_params =
      if status == Trip.finished() do
        trip_params
        |> Map.merge(%{"dates_unknown" => false})
      else
        trip_params
      end

    {:noreply,
     socket
     |> assign(status: status)
     |> assign_form(trip_params)}
  end

  @impl true
  def handle_event(
        "form_changed",
        %{
          "trip" => trip_params
        },
        socket
      ) do
    {:noreply, socket |> assign_form(trip_params)}
  end

  @impl true
  def handle_event("form_submit", %{"trip" => trip_params}, socket) do
    trip_params = normalize_trip_params(socket, trip_params)
    on_submit(socket, socket.assigns.action, trip_params)
  end

  def on_submit(%{assigns: %{copy_from: trip}} = socket, :new, trip_params) when trip != nil do
    trip_params
    |> Planning.create_trip(socket.assigns.current_user, trip)
    |> result(socket)
  end

  def on_submit(socket, :new, trip_params) do
    trip_params
    |> Planning.create_trip(socket.assigns.current_user)
    |> result(socket)
  end

  def on_submit(socket, :edit, trip_params) do
    socket.assigns.trip
    |> Planning.update_trip(trip_params)
    |> result(socket)
  end

  def result({:ok, trip}, socket) do
    socket =
      socket
      |> push_navigate(to: ~p"/trips/#{trip.slug}")

    {:noreply, socket}
  end

  def result({:error, changeset}, socket) do
    {:noreply,
     socket
     |> assign_trip_fields(changeset)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, trip_params) when is_map(trip_params) do
    assign_form(socket, Planning.trip_changeset(trip_params))
  end

  defp normalize_trip_params(socket, trip_params) do
    status = Map.get(trip_params, "status", socket.assigns.status)

    if status == Trip.finished() do
      Map.put(trip_params, "dates_unknown", false)
    else
      trip_params
    end
  end

  defp assign_trip_fields(socket, changeset) do
    socket
    |> assign(:dates_unknown, Changeset.get_field(changeset, :dates_unknown))
    |> assign(:start_date, Changeset.get_field(changeset, :start_date))
    |> assign(:end_date, Changeset.get_field(changeset, :end_date))
    |> assign(:status, Changeset.get_field(changeset, :status))
  end

  defp selected_duration(form) do
    Dates.duration(form[:start_date].value, form[:end_date].value)
  end
end
