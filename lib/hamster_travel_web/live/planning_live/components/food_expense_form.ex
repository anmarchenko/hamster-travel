defmodule HamsterTravelWeb.Planning.FoodExpenseForm do
  @moduledoc """
  Food expense edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.FoodExpense

  attr :food_expense, FoodExpense, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :display_currency, :string, required: true
  attr :on_finish, :fun, required: true
  attr :can_edit, :boolean, default: false

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id={"food-expense-form-#{@food_expense.id}"}
        for={@form}
        as={:food_expense}
        phx-target={@myself}
        phx-change="form_changed"
        phx-submit="form_submit"
        class="space-y-4 max-w-2xl"
      >
        <div class="grid grid-cols-1 sm:grid-cols-4 gap-4 items-start">
          <div class="sm:col-span-2">
            <.money_input
              id={"food-expense-price-per-day-#{@food_expense.id}"}
              field={@form[:price_per_day]}
              label={gettext("Price per day per person")}
              default_currency={@trip.currency}
            />
          </div>

          <div class="sm:col-span-1">
            <.field
              field={@form[:days_count]}
              type="number"
              min="1"
              step="1"
              label={gettext("Days")}
            />
          </div>

          <div class="sm:col-span-1">
            <.field
              field={@form[:people_count]}
              type="number"
              min="1"
              step="1"
              label={gettext("People")}
            />
          </div>
        </div>

        <div class="text-sm text-zinc-500">
          <span class="font-medium text-zinc-700 dark:text-zinc-300">{gettext("Total")}</span>
          <.money_display
            money={@total}
            display_currency={@display_currency}
            class="ml-2 inline-flex"
          />
        </div>

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
    changeset = Planning.change_food_expense(assigns.food_expense)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("form_changed", %{"food_expense" => params}, socket) do
    changeset = FoodExpense.changeset(socket.assigns.food_expense, params)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("form_submit", %{"food_expense" => params}, socket) do
    if socket.assigns.can_edit do
      socket.assigns.food_expense
      |> Planning.update_food_expense(params)
      |> result(socket)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    total = FoodExpense.food_expense_total(changeset, socket.assigns.trip.currency)

    socket
    |> assign(:changeset, changeset)
    |> assign(:form, to_form(changeset))
    |> assign(:total, total)
  end

  defp result({:ok, _food_expense}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end
end
