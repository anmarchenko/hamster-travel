defmodule HamsterTravelWeb.Planning.BudgetCategoryActualExpense do
  @moduledoc """
  Displays and edits one actual expense recorded for a budget category.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :edit, false)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form(Planning.change_expense(assigns.expense))

    {:ok, socket}
  end

  attr :expense, HamsterTravel.Planning.Expense, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :display_currency, :string, required: true
  attr :can_edit, :boolean, default: false

  @impl true
  def render(%{edit: true} = assigns) do
    ~H"""
    <div id={"budget-category-actual-#{@expense.id}"}>
      <.form
        id={"budget-category-actual-form-#{@expense.id}"}
        for={@form}
        as={:expense}
        phx-target={@myself}
        phx-submit="save"
        phx-mounted={JS.focus_first(to: "#budget-category-actual-form-#{@expense.id}")}
        class="ml-4 flex max-w-2xl flex-col gap-3 border-l border-zinc-200 py-2 pl-4 sm:flex-row sm:items-start dark:border-zinc-700"
      >
        <div class="grow">
          <.money_input
            id={"budget-category-actual-price-#{@expense.id}"}
            field={@form[:price]}
            label={gettext("Actual expense")}
            default_currency={@trip.currency}
            reserve_error_space
          />
        </div>
        <div class="flex items-center justify-between gap-2 sm:mt-7">
          <.icon_button
            size="xs"
            type="button"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure you want to delete this actual expense?")}
            aria-label={gettext("Delete")}
            title={gettext("Delete")}
            class="!h-9 !w-9 shrink-0 text-slate-500 hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400"
          >
            <.icon name="hero-trash" class="h-4 w-4" />
          </.icon_button>
          <div class="flex gap-2">
            <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
              {gettext("Cancel")}
            </.button>
            <.button color="primary" size="xs" type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      id={"budget-category-actual-#{@expense.id}"}
      class="ml-4 flex min-h-8 max-w-3xl items-center border-l border-zinc-200 py-1 pl-4 text-sm text-zinc-500 dark:border-zinc-700 dark:text-zinc-400"
    >
      <button
        :if={@can_edit}
        type="button"
        phx-click="edit"
        phx-target={@myself}
        aria-label={gettext("Edit")}
        title={gettext("Edit")}
        class="group ml-auto flex min-h-8 shrink-0 items-center justify-end rounded-sm px-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 sm:w-44"
      >
        <.money_display
          money={@expense.price}
          display_currency={@display_currency}
          class="text-right text-sm font-normal tabular-nums text-zinc-500 transition-colors group-hover:text-primary-600 group-hover:underline group-hover:decoration-dotted group-hover:underline-offset-4 dark:text-zinc-400 dark:group-hover:text-primary-300"
        />
      </button>
      <div :if={!@can_edit} class="ml-auto flex shrink-0 justify-end sm:w-44">
        <.money_display
          money={@expense.price}
          display_currency={@display_currency}
          class="text-right text-sm font-normal tabular-nums text-zinc-500 dark:text-zinc-400"
        />
      </div>
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

  def handle_event("save", %{"expense" => params}, socket) do
    if socket.assigns.can_edit do
      socket.assigns.expense
      |> Planning.update_budget_category_actual_expense(params)
      |> result(socket)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _params, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_budget_category_actual_expense(socket.assigns.expense) do
        {:ok, _expense} ->
          {:noreply, socket}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete expense"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  defp result({:ok, expense}, socket) do
    {:noreply,
     socket
     |> assign(:expense, expense)
     |> assign(:edit, false)
     |> assign_form(Planning.change_expense(expense))}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
