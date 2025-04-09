defmodule HamsterTravelWeb.Planning.DestinationForm do
  @moduledoc """
  Destination create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo

  alias HamsterTravelWeb.Planning.CityInput
  alias HamsterTravelWeb.Planning.DayRangeSelect

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="destination-form"
        for={@form}
        as={:destination}
        phx-target={@myself}
        phx-submit="form_submit"
        class="space-y-4"
      >
        <.live_component
          id={"destination-form-city-input-#{:rand.uniform(1000)}"}
          module={CityInput}
          field={@form[:city]}
          label={gettext("City")}
        />
        <!-- take duration and start date from trip -->
        <.live_component
          id={"destination-put-destination-id-here-#{:rand.uniform(1000)}-form-day-range-select"}
          module={DayRangeSelect}
          start_day_field={@form[:start_day]}
          end_day_field={@form[:end_day]}
          label={gettext("Date range")}
          duration={5}
          start_date={Date.utc_today()}
        />
        <div class="flex justify-between mt-2">
          <.button color="primary" size="xs">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    [city | _] = Geo.search_cities("lis")

    changeset =
      {%{city: city, start_day: 0, end_day: 1},
       %{city: :map, start_day: :integer, end_day: :integer}}
      |> Ecto.Changeset.cast(%{}, [:city])

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset, as: :destination))

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"destination" => _destination_params}, socket) do
    {:noreply, socket}
  end
end
