defmodule HamsterTravelWeb.Planning.BudgetExpense do
  @moduledoc """
  Amount-only editor for expenses shown on the Budget tab.
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  @impl true
  def mount(socket) do
    {:ok, assign(socket, edit: false)}
  end

  @impl true
  def update(assigns, socket) do
    changeset = Planning.change_expense(assigns.expense)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def render(%{edit: true} = assigns) do
    ~H"""
    <div id={"budget-expense-#{@source}-#{@expense.id}"} class="w-full max-w-3xl py-1.5">
      <.form
        id={"budget-expense-form-#{@source}-#{@expense.id}"}
        for={@form}
        as={:expense}
        phx-target={@myself}
        phx-submit="form_submit"
        phx-mounted={JS.focus_first(to: "#budget-expense-form-#{@source}-#{@expense.id}")}
        class="flex flex-col gap-3 sm:flex-row sm:items-end"
      >
        <div class="min-w-0 grow">
          <div class="mb-1 truncate text-sm font-medium text-zinc-900 dark:text-zinc-100">
            {@label}
          </div>
          <.money_input
            id={"budget-expense-price-#{@source}-#{@expense.id}"}
            field={@form[:price]}
            label={gettext("Price")}
            default_currency={@trip.currency}
          />
        </div>
        <div class="flex justify-between gap-2 sm:justify-start">
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

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      id={"budget-expense-#{@source}-#{@expense.id}"}
      class="flex w-full max-w-3xl flex-col gap-y-1 rounded-md py-1.5"
    >
      <.inline class="w-full gap-2 2xl:text-lg">
        <span class="flex min-w-0 flex-1 items-center gap-1.5">
          <span class="min-w-0 truncate">{@label}</span>
          <.edit_delete_buttons
            :if={@can_edit}
            class="shrink-0"
            edit_target={@myself}
            show_delete={false}
          />
        </span>
        <div class="ml-auto flex shrink-0 items-center justify-end sm:w-44">
          <.money_display
            money={@expense.price}
            display_currency={@display_currency}
            class="text-right text-base font-normal tabular-nums text-zinc-500 dark:text-zinc-400 2xl:text-lg"
          />
        </div>
      </.inline>
    </div>
    """
  end

  @impl true
  def handle_event("edit", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :edit, true)}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, :edit, false)}
  end

  def handle_event("form_submit", %{"expense" => expense_params}, socket) do
    if socket.assigns.can_edit do
      socket.assigns
      |> update_source_item(expense_params)
      |> result(socket)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  defp update_source_item(assigns, expense_params) do
    expense_params = Map.put(expense_params, "id", assigns.expense.id)
    attrs = %{"expense" => expense_params}

    case assigns.source do
      "hotel" -> Planning.update_accommodation(assigns.source_item, attrs)
      "transfer" -> Planning.update_transfer(assigns.source_item, attrs)
      "activity" -> Planning.update_activity(assigns.source_item, attrs)
    end
  end

  defp result({:ok, source_item}, socket) do
    expense = source_item.expense

    {:noreply,
     socket
     |> assign(:source_item, source_item)
     |> assign(:expense, expense)
     |> assign(:edit, false)
     |> assign_form(Planning.change_expense(expense))}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, expense_changeset(changeset, socket.assigns.expense))}
  end

  defp expense_changeset(%Ecto.Changeset{} = source_changeset, expense) do
    Ecto.Changeset.get_change(source_changeset, :expense) || Planning.change_expense(expense)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
