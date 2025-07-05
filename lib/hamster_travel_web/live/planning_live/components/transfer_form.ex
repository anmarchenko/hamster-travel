defmodule HamsterTravelWeb.Planning.TransferForm do
  @moduledoc """
  Transfer create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  alias HamsterTravelWeb.Planning.CityInput

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, required: true
  attr :on_finish, :fun, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id={"transfer-form-#{@id}"}
        for={@form}
        as={:transfer}
        phx-target={@myself}
        phx-submit="form_submit"
        class="space-y-4"
      >
        <.field
          type="select"
          field={@form[:transport_mode]}
          label={gettext("Transport")}
          options={transport_mode_options()}
          required
        />

        <div class="grid grid-cols-1 md:grid-cols-9 gap-4 items-end">
          <div class="md:col-span-4">
            <.live_component
              id={"departure-city-input-#{@id}"}
              module={CityInput}
              field={@form[:departure_city]}
              validated_field={@form[:departure_city_id]}
              label={gettext("Departure city")}
            />
          </div>

          <div class="hidden md:flex justify-center items-center text-gray-400 pb-2">
            <.icon name="hero-arrow-right" class="w-6 h-6" />
          </div>

          <div class="md:col-span-4">
            <.live_component
              id={"arrival-city-input-#{@id}"}
              module={CityInput}
              field={@form[:arrival_city]}
              validated_field={@form[:arrival_city_id]}
              label={gettext("Arrival city")}
            />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="md:col-span-1">
            <.field
              field={@form[:departure_time]}
              type="time"
              label={gettext("Departure time")}
              wrapper_class="mb-0"
            />
          </div>

          <div class="md:col-span-1">
            <.field
              field={@form[:arrival_time]}
              type="time"
              label={gettext("Arrival time")}
              wrapper_class="mb-0"
            />
          </div>
        </div>

        <.inputs_for :let={expense_form} field={@form[:expense]}>
          <.money_input
            id={"transfer-expense-price-#{@id}"}
            field={expense_form[:price]}
            label={gettext("Price")}
            default_currency={@trip.currency}
          />
        </.inputs_for>

        <%!-- <.field
          field={@form[:vessel_number]}
          type="text"
          label={gettext("Vessel Number")}
          placeholder={gettext("Flight number, train number, etc.")}
        />

        <.field
          field={@form[:carrier]}
          type="text"
          label={gettext("Carrier")}
          placeholder={gettext("Airline, train company, etc.")}
        /> --%>

        <%!-- <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.field
            field={@form[:departure_station]}
            type="text"
            label={gettext("Departure Station")}
            placeholder={gettext("Airport, train station, etc.")}
          />

          <.field
            field={@form[:arrival_station]}
            type="text"
            label={gettext("Arrival Station")}
            placeholder={gettext("Airport, train station, etc.")}
          />
        </div> --%>

        <.field
          field={@form[:note]}
          type="textarea"
          label={gettext("Note")}
          placeholder={gettext("Additional transfer details")}
        />

        <.field field={@form[:day_index]} type="hidden" />

        <div class="flex justify-between mt-2">
          <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
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
          Planning.new_transfer(assigns.trip, assigns.day_index)

        :edit ->
          Planning.change_transfer(assigns.transfer)
          |> convert_datetime_to_time_for_form()
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  # Convert datetime fields to time format for form display
  defp convert_datetime_to_time_for_form(changeset) do
    changeset
    |> convert_field_to_time(:departure_time)
    |> convert_field_to_time(:arrival_time)
  end

  defp convert_field_to_time(changeset, field) do
    case Ecto.Changeset.get_field(changeset, field) do
      %DateTime{} = datetime ->
        # Convert to HH:MM format (without seconds)
        time = DateTime.to_time(datetime)

        time_string =
          "#{String.pad_leading(Integer.to_string(time.hour), 2, "0")}:#{String.pad_leading(Integer.to_string(time.minute), 2, "0")}"

        Ecto.Changeset.put_change(changeset, field, time_string)

      _ ->
        changeset
    end
  end

  @impl true
  def handle_event("form_submit", %{"transfer" => transfer_params}, socket) do
    transfer_params =
      transfer_params
      |> CityInput.process_selected_value_on_submit("departure_city")
      |> CityInput.process_selected_value_on_submit("arrival_city")

    on_submit(socket, socket.assigns.action, transfer_params)
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp on_submit(socket, :new, transfer_params) do
    socket.assigns.trip
    |> Planning.create_transfer(transfer_params)
    |> result(socket)
  end

  defp on_submit(socket, :edit, transfer_params) do
    socket.assigns.transfer
    |> Planning.update_transfer(transfer_params)
    |> result(socket)
  end

  defp result({:ok, _transfer}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end

  defp transport_mode_options do
    Planning.Transfer.transport_modes()
    |> Enum.map(fn mode ->
      {transport_mode_label(mode), mode}
    end)
  end

  defp transport_mode_label("flight"), do: gettext("Flight")
  defp transport_mode_label("train"), do: gettext("Train")
  defp transport_mode_label("bus"), do: gettext("Bus")
  defp transport_mode_label("car"), do: gettext("Car")
  defp transport_mode_label("taxi"), do: gettext("Taxi")
  defp transport_mode_label("boat"), do: gettext("Boat")
  defp transport_mode_label(mode), do: String.capitalize(mode)
end
