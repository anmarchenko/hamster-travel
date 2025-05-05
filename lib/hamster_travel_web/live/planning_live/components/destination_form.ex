defmodule HamsterTravelWeb.Planning.DestinationForm do
  @moduledoc """
  Destination create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning

  alias HamsterTravelWeb.Planning.CityInput
  alias HamsterTravelWeb.Planning.DayRangeSelect

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :on_finish, :fun, required: true

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
          id={"city-input-#{@id}"}
          module={CityInput}
          field={@form[:city]}
          validated_field={@form[:city_id]}
          label={gettext("City")}
        />
        <.live_component
          id={"day-range-#{@id}"}
          module={DayRangeSelect}
          start_day_field={@form[:start_day]}
          end_day_field={@form[:end_day]}
          label={gettext("Date range")}
          duration={@trip.duration}
          start_date={@trip.start_date}
        />
        <div class="flex justify-between mt-2">
          <.button color="white" type="button" phx-click="cancel" phx-target={@myself}>
            {gettext("Cancel")}
          </.button>
          <.button color="primary" size="xs" type="submit">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset =
      case assigns.action do
        :new ->
          Planning.new_destination(assigns.trip)

        :edit ->
          Planning.change_destination(assigns.destination)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"destination" => destination_params}, socket) do
    city_input_value = Map.get(destination_params, "city")

    city_json =
      if city_input_value != nil && city_input_value != "",
        do: Jason.decode!(city_input_value),
        else: %{}

    city_id = Map.get(city_json, "id")
    city = if city_id != nil, do: Geo.get_city(city_id), else: nil

    destination_params =
      destination_params
      |> Map.put("city_id", city_id)
      |> Map.put("city", city)

    case Planning.create_destination(socket.assigns.trip, destination_params) do
      {:ok, _destination} ->
        socket.assigns.on_finish.()
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
