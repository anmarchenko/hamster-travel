defmodule HamsterTravelWeb.Planning.ActivityForm do
  @moduledoc """
  Activity create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, required: true
  attr :on_finish, :fun, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id={"activity-form-#{@id}"}
        for={@form}
        as={:activity}
        phx-target={@myself}
        phx-submit="form_submit"
        phx-change="form_changed"
        class="space-y-4"
      >
        <div class="flex flex-col md:flex-row gap-4">
          <div class="flex-grow">
            <.field
              field={@form[:name]}
              type="text"
              label={gettext("Activity Name")}
              placeholder={gettext("e.g. Visit the Louvre")}
              required
            />
          </div>
          <div class="flex-shrink-0 pt-2">
            <.label>{gettext("Priority")}</.label>
            <.rating_input field={@form[:priority]} max={3} icon="hero-star-solid" />
          </div>
        </div>

        <.field
          field={@form[:link]}
          type="text"
          label={gettext("Link")}
          placeholder={gettext("https://...")}
        />

        <.field
          field={@form[:address]}
          type="text"
          label={gettext("Address")}
          placeholder={gettext("e.g. Rue de Rivoli, 75001 Paris")}
        />

        <.formatted_text_area
          field={@form[:description]}
          label={gettext("Description")}
          placeholder={gettext("Details about the activity")}
        />

        <.inputs_for :let={expense_form} field={@form[:expense]}>
          <.money_input
            id={"activity-expense-price-#{@id}"}
            field={expense_form[:price]}
            label={gettext("Price")}
            default_currency={@trip.currency}
          />
        </.inputs_for>

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
          Planning.new_activity(assigns.trip, assigns.day_index)

        :edit ->
          Planning.change_activity(assigns.activity)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"activity" => activity_params}, socket) do
    on_submit(socket, socket.assigns.action, activity_params)
  end

  def handle_event("form_changed", %{"activity" => _activity_params}, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp on_submit(socket, :new, activity_params) do
    socket.assigns.trip
    |> Planning.create_activity(activity_params)
    |> result(socket)
  end

  defp on_submit(socket, :edit, activity_params) do
    socket.assigns.activity
    |> Planning.update_activity(activity_params)
    |> result(socket)
  end

  defp result({:ok, _activity}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end
end
