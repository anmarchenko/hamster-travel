defmodule HamsterTravelWeb.Planning.DestinationForm do
  @moduledoc """
  Destination create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  alias HamsterTravelWeb.CityInput
  alias HamsterTravelWeb.Planning.DayRangeSelect

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, required: true
  attr :on_finish, :fun, required: true
  attr :can_edit, :boolean, default: false

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id={"destination-form-#{@id}"}
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
          Planning.new_destination(assigns.trip, assigns.day_index)

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
    if socket.assigns.can_edit do
      destination_params = CityInput.process_selected_value_on_submit(destination_params, "city")

      on_submit(socket, socket.assigns.action, destination_params)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp on_submit(socket, :new, destination_params) do
    socket.assigns.trip
    |> Planning.create_destination(destination_params)
    |> result(socket)
  end

  defp on_submit(socket, :edit, destination_params) do
    socket.assigns.destination
    |> Planning.update_destination(destination_params)
    |> result(socket)
  end

  defp result({:ok, _destination}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end
end
