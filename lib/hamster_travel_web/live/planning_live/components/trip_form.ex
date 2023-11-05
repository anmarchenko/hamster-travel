defmodule HamsterTravelWeb.Planning.TripForm do
  @moduledoc """
  Live trip create/edit form
  """

  alias HamsterTravel.Planning
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning.Trip

  alias Ecto.Changeset

  @impl true
  def mount(socket) do
    IO.inspect("MOUNT EVENT")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    IO.inspect("UPDATE EVENT")

    socket =
      socket
      |> assign(assigns)
      |> assign(dates_unknown: Changeset.get_field(assigns.changeset, :dates_unknown))
      |> assign(start_date: Changeset.get_field(assigns.changeset, :start_date))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    IO.inspect("RENDER")
    form = to_form(assigns.changeset)

    ~H"""
    <div>
      <.form_container>
        <.form
          for={form}
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
                type="select"
                options={for status <- Trip.statuses(), do: {status, status}}
              />
            </div>
            <div class="col-span-6">
              <.field
                type="hidden"
                field={@form[:currency]}
                label={gettext("Trip currency")}
                required={true}
              />
            </div>
            <div class="col-span-6">
              <.field
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

            <%!-- TODO: add min, max constraints --%>
            <div :if={!@dates_unknown} class="col-span-3">
              <.field
                type="date"
                field={@form[:end_date]}
                label={gettext("End date")}
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
        socket
      ) do
    IO.inspect("FORM CHANGED EVENT with dates unknown")

    {:noreply,
     assign(socket,
       dates_unknown: dates_unknown,
       changeset: Planning.trip_changeset(trip_params),
       form: to_form(Planning.trip_changeset(trip_params))
     )}
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
    handler = socket.assigns.on_submit
    handler.(socket, trip_params)
  end
end
