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
  attr :can_edit, :boolean, default: false
  attr :position, :integer, default: nil

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
        phx-mounted={JS.focus_first(to: "#activity-form-#{@id}")}
        class="space-y-4"
      >
        <div
          :if={@position}
          class="flex items-center gap-3 rounded-md border border-primary-200 bg-primary-50 px-3 py-2 text-primary-950 dark:border-primary-900 dark:bg-primary-950/30 dark:text-primary-100"
        >
          <span class="inline-flex h-8 min-w-8 shrink-0 items-center justify-center rounded-md bg-primary-100 px-2 text-sm font-semibold tabular-nums dark:bg-primary-900">
            {@position}
          </span>
          <div class="min-w-0">
            <p class="text-sm font-semibold leading-snug">
              {activity_form_title(assigns)}
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-3 md:gap-8 items-stretch">
          <div class="space-y-4 md:col-span-1">
            <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
              <div class="grow">
                <.field
                  field={@form[:name]}
                  type="text"
                  label={gettext("Activity Name")}
                  wrapper_class="mb-0"
                  placeholder={gettext("e.g. Visit the Louvre")}
                  required
                />
              </div>
              <div class="flex flex-col gap-1">
                <.label>{gettext("Priority")}</.label>
                <.rating_input field={@form[:priority]} max={3} icon="hero-star-solid" />
              </div>
            </div>

            <.inputs_for :let={expense_form} field={@form[:expense]}>
              <.money_input
                id={"activity-expense-price-#{@id}"}
                field={expense_form[:price]}
                label={gettext("Price")}
                default_currency={@trip.currency}
              />
            </.inputs_for>

            <.field
              field={@form[:link]}
              type="text"
              label={gettext("Link")}
              placeholder="https://..."
            />

            <.field
              field={@form[:address]}
              type="text"
              label={gettext("Address")}
              placeholder={gettext("e.g. Rue de Rivoli, 75001 Paris")}
            />

            <div class="hidden md:flex justify-between mt-2">
              <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
                {gettext("Cancel")}
              </.button>
              <.button color="primary" size="xs" type="submit">
                {gettext("Save")}
              </.button>
            </div>
          </div>

          <div class="md:col-span-2 flex flex-col h-full">
            <.formatted_text_area
              field={@form[:description]}
              label={gettext("Description")}
              wrapper_class="mb-0 flex-1 flex flex-col h-full"
              class="mt-0 flex-1 min-h-0"
              content_class="py-0 min-h-0"
            />
          </div>
        </div>

        <div class="flex md:hidden justify-between mt-4">
          <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
            {gettext("Cancel")}
          </.button>
          <.button color="primary" size="xs" type="submit">
            {gettext("Save")}
          </.button>
        </div>

        <.field field={@form[:day_index]} type="hidden" />
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
    if socket.assigns.can_edit do
      on_submit(socket, socket.assigns.action, activity_params)
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

  defp activity_form_title(%{action: :new}) do
    gettext("Add new activity")
  end

  defp activity_form_title(%{action: :edit, activity: activity}) do
    activity.name
  end
end
