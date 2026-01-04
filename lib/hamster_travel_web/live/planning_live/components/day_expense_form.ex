defmodule HamsterTravelWeb.Planning.DayExpenseForm do
  @moduledoc """
  Day expense create/edit form.
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
        id={"day-expense-form-#{@id}"}
        for={@form}
        as={:day_expense}
        phx-target={@myself}
        phx-submit="form_submit"
        class="space-y-4 max-w-lg"
      >
        <div class="flex flex-col gap-4 sm:flex-row sm:items-end">
          <div class="grow">
            <.field
              field={@form[:name]}
              type="text"
              label={gettext("Expense name")}
              wrapper_class="mb-0"
              placeholder={gettext("e.g. Transport card")}
              required
            />
          </div>

          <.inputs_for :let={expense_form} field={@form[:expense]}>
            <.money_input
              id={"day-expense-price-#{@id}"}
              field={expense_form[:price]}
              label={gettext("Price")}
              default_currency={@trip.currency}
            />
          </.inputs_for>
        </div>

        <div class="flex justify-between mt-2">
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
          Planning.new_day_expense(assigns.trip, assigns.day_index)

        :edit ->
          Planning.change_day_expense(assigns.day_expense)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"day_expense" => day_expense_params}, socket) do
    on_submit(socket, socket.assigns.action, day_expense_params)
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp on_submit(socket, :new, day_expense_params) do
    socket.assigns.trip
    |> Planning.create_day_expense(day_expense_params)
    |> result(socket)
  end

  defp on_submit(socket, :edit, day_expense_params) do
    socket.assigns.day_expense
    |> Planning.update_day_expense(day_expense_params)
    |> result(socket)
  end

  defp result({:ok, _day_expense}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end
end
