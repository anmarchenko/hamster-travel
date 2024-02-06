defmodule HamsterTravelWeb.Planning.Trips.FormComponent do
  @moduledoc """
  Live trip create/edit form
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Dates
  alias HamsterTravel.Planning

  alias HamsterTravel.Planning.Trip

  alias HamsterTravelWeb.Cldr

  alias Ecto.Changeset

  @impl true
  def update(assigns, socket) do
    changeset =
      case assigns.action do
        :new ->
          Planning.new_trip()

        _ ->
          Planning.change_trip(assigns.trip)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
      |> assign(:dates_unknown, Changeset.get_field(changeset, :dates_unknown))
      |> assign(:start_date, Changeset.get_field(changeset, :start_date))
      |> assign(:end_date, Changeset.get_field(changeset, :end_date))
      |> assign(:status, Changeset.get_field(changeset, :status))
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form_container>
        <.form
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
                options={
                  for currency <- Money.known_current_currencies(),
                      do: {Cldr.localize_currency(currency), currency}
                }
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
            <div :if={!@dates_unknown} class="col-span-3">
              <.field
                type="date"
                field={@form[:start_date]}
                label={gettext("Start date")}
                required={true}
              />
            </div>

            <div :if={!@dates_unknown} class="col-span-3">
              <.field
                type="date"
                field={@form[:end_date]}
                label={gettext("End date")}
                min={@start_date}
                max={max_end_date(@start_date)}
                required={true}
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
              <%= gettext("Cancel") %>
            </.button>
            <.button color="primary">
              <%= gettext("Save") %>
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

    new_changeset =
      trip_params
      |> Map.merge(%{
        "start_date" => assigns.start_date,
        "end_date" => assigns.end_date,
        "duration" => Dates.duration(assigns.start_date, assigns.end_date)
      })
      |> Planning.trip_changeset()

    {:noreply,
     socket
     |> assign(:dates_unknown, dates_unknown)
     |> assign(:changeset, new_changeset)
     |> assign_form(new_changeset)}
  end

  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "start_date"],
          "trip" => %{"start_date" => start_date}
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(start_date: start_date)}
  end

  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "end_date"],
          "trip" => %{"end_date" => end_date}
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(end_date: end_date)}
  end

  def handle_event(
        "form_changed",
        %{
          "_target" => ["trip", "status"],
          "trip" => %{"status" => status}
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

    {:noreply,
     socket
     |> assign(status: status)}
  end

  @impl true
  def handle_event(
        "form_changed",
        _,
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("form_submit", %{"trip" => trip_params}, socket) do
    on_submit(socket, socket.assigns.action, trip_params)
  end

  def on_submit(socket, :new, trip_params) do
    trip_params
    |> Planning.create_trip(socket.assigns.current_user)
    |> result(socket, :new)
  end

  def result({:ok, trip}, socket, :new) do
    socket =
      socket
      |> push_redirect(to: ~p"/trips/#{trip.slug}")

    {:noreply, socket}
  end

  def result({:error, changeset}, socket, _) do
    {
      :noreply,
      socket
      |> assign(:changeset, changeset)
      |> assign_form(changeset)
    }
  end

  defp max_end_date(nil), do: nil

  defp max_end_date(start_date) do
    start_date = Dates.parse_iso_date_or(start_date)
    # parse start_date as date
    case start_date do
      nil ->
        nil

      %Date{} ->
        Date.add(start_date, 29)
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
