defmodule HamsterTravelWeb.Planning.AccommodationForm do
  @moduledoc """
  Accommodation create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

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
        id={"accommodation-form-#{@id}"}
        for={@form}
        as={:accommodation}
        phx-target={@myself}
        phx-submit="form_submit"
        class="space-y-4"
      >
        <.field
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          wrapper_class="mb-0"
          placeholder={gettext("Hotel name")}
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

        <.inputs_for :let={expense_form} field={@form[:expense]}>
          <.money_input
            id={"accommodation-expense-price-#{@id}"}
            field={expense_form[:price]}
            label={gettext("Price")}
            default_currency={@trip.currency}
          />
        </.inputs_for>

        <.field
          field={@form[:link]}
          type="url"
          label={gettext("Link")}
          placeholder={gettext("Website link")}
        />

        <.field
          field={@form[:address]}
          type="text"
          label={gettext("Address")}
          placeholder={gettext("Street address")}
        />

        <.formatted_text_area
          field={@form[:note]}
          label={gettext("Note")}
          placeholder={gettext("Additional notes or details")}
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
          Planning.new_accommodation(assigns.trip, assigns.day_index)

        :edit ->
          Planning.change_accommodation(assigns.accommodation)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"accommodation" => accommodation_params}, socket) do
    if socket.assigns.can_edit do
      on_submit(socket, socket.assigns.action, accommodation_params)
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

  defp on_submit(socket, :new, accommodation_params) do
    socket.assigns.trip
    |> Planning.create_accommodation(accommodation_params)
    |> result(socket)
  end

  defp on_submit(socket, :edit, accommodation_params) do
    socket.assigns.accommodation
    |> Planning.update_accommodation(accommodation_params)
    |> result(socket)
  end

  defp result({:ok, _accommodation}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end
end
