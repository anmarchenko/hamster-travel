defmodule HamsterTravelWeb.Planning.TransferForm do
  @moduledoc """
  Transfer create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  alias HamsterTravelWeb.CityInput

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :current_user, HamsterTravel.Accounts.User, default: nil
  attr :day_index, :integer, required: true
  attr :on_finish, :fun, required: true
  attr :can_edit, :boolean, default: false

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
        phx-change="form_changed"
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
              trip_cities={get_destination_cities(@trip, assigns)}
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
              trip_cities={get_destination_cities(@trip, assigns)}
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

        <.field field={@form[:plus_one_day]} type="checkbox" label={gettext("Next day")} />

        <.inputs_for :let={expense_form} field={@form[:expense]}>
          <.money_input
            id={"transfer-expense-price-#{@id}"}
            field={expense_form[:price]}
            label={gettext("Price")}
            default_currency={@trip.currency}
          />
        </.inputs_for>

        <div :if={@show_carrier_info} class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="md:col-span-1">
            <.field
              field={@form[:departure_station]}
              type="text"
              label={departure_station_label(@transport_mode)}
              wrapper_class="mb-0"
            />
          </div>

          <div class="md:col-span-1">
            <.field
              field={@form[:arrival_station]}
              type="text"
              label={arrival_station_label(@transport_mode)}
              wrapper_class="mb-0"
            />
          </div>
        </div>

        <div :if={@show_carrier_info} class="grid grid-cols-1 md:grid-cols-8 gap-4">
          <div class="md:col-span-2">
            <.field
              field={@form[:vessel_number]}
              type="text"
              label={vessel_number_label(@transport_mode)}
              wrapper_class="mb-0"
            />
          </div>

          <div class="md:col-span-6">
            <.field
              field={@form[:carrier]}
              type="text"
              label={carrier_label(@transport_mode)}
              wrapper_class="mb-0"
            />
          </div>
        </div>

        <.formatted_text_area
          field={@form[:note]}
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

    transport_mode = Ecto.Changeset.get_field(changeset, :transport_mode)

    socket =
      socket
      |> assign(assigns)
      |> assign(:transport_mode, transport_mode)
      |> assign(:show_carrier_info, show_carrier_info(transport_mode))
      |> assign_form(changeset)

    {:ok, socket}
  end

  # Convert datetime fields to time format for form display
  defp convert_datetime_to_time_for_form(changeset) do
    changeset
    |> set_plus_one_day_from_datetime()
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

  defp set_plus_one_day_from_datetime(changeset) do
    case Ecto.Changeset.get_field(changeset, :departure_time) do
      %DateTime{} = datetime ->
        date = DateTime.to_date(datetime)

        if Date.compare(date, ~D[1970-01-02]) == :eq do
          Ecto.Changeset.put_change(changeset, :plus_one_day, true)
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  @impl true
  def handle_event("form_submit", %{"transfer" => transfer_params}, socket) do
    if socket.assigns.can_edit do
      transfer_params =
        transfer_params
        |> CityInput.process_selected_value_on_submit("departure_city")
        |> CityInput.process_selected_value_on_submit("arrival_city")
        |> cleanup_carrier_fields_if_not_shown(socket.assigns.show_carrier_info)

      on_submit(socket, socket.assigns.action, transfer_params)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("form_changed", %{"transfer" => %{"transport_mode" => transport_mode}}, socket) do
    socket =
      socket
      |> assign(:transport_mode, transport_mode)
      |> assign(:show_carrier_info, show_carrier_info(transport_mode))

    {:noreply, socket}
  end

  def handle_event("form_changed", %{"transfer" => _transfer_params}, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp cleanup_carrier_fields_if_not_shown(transfer_params, true), do: transfer_params

  defp cleanup_carrier_fields_if_not_shown(transfer_params, false) do
    transfer_params
    |> Map.put("vessel_number", nil)
    |> Map.put("carrier", nil)
    |> Map.put("departure_station", nil)
    |> Map.put("arrival_station", nil)
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
    {:noreply, assign_form(socket, convert_datetime_to_time_for_form(changeset))}
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

  defp show_carrier_info("flight"), do: true
  defp show_carrier_info("train"), do: true
  defp show_carrier_info(_), do: false

  defp vessel_number_label("flight"), do: gettext("Flight number")
  defp vessel_number_label("train"), do: gettext("Train number")
  defp vessel_number_label(_), do: gettext("Vessel")

  defp carrier_label("flight"), do: gettext("Airline")
  defp carrier_label("train"), do: gettext("Railway")
  defp carrier_label(_), do: gettext("Carrier")

  defp departure_station_label("flight"), do: gettext("Departure airport")
  defp departure_station_label("train"), do: gettext("Departure station")
  defp departure_station_label(_), do: gettext("Departure station")

  defp arrival_station_label("flight"), do: gettext("Arrival airport")
  defp arrival_station_label("train"), do: gettext("Arrival station")
  defp arrival_station_label(_), do: gettext("Arrival station")

  defp get_destination_cities(trip, %{action: :edit, transfer: transfer} = assigns) do
    destination_cities = extract_destination_cities(trip)

    transfer_cities =
      [transfer.departure_city, transfer.arrival_city]
      |> Enum.reject(&is_nil/1)

    [home_city(assigns[:current_user]) | transfer_cities ++ destination_cities]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(& &1.id)
  end

  defp get_destination_cities(trip, assigns) do
    trip
    |> extract_destination_cities()
    |> then(fn destination_cities -> [home_city(assigns[:current_user]) | destination_cities] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(& &1.id)
  end

  defp extract_destination_cities(trip) do
    trip.destinations
    |> Enum.map(& &1.city)
    |> Enum.reject(&is_nil/1)
  end

  defp home_city(nil), do: nil
  defp home_city(%{home_city: home_city}), do: home_city
end
