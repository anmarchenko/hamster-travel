defmodule HamsterTravelWeb.Planning.DayExpense do
  @moduledoc """
  Live component responsible for showing and editing day expenses.
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{DayExpense, Trip}

  attr(:day_expense, DayExpense, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.DayExpenseForm}
        id={"day-expense-form-#{@day_expense.id}"}
        day_expense={@day_expense}
        trip={@trip}
        day_index={@day_expense.day_index}
        action={:edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      class="draggable-day-expense flex flex-col gap-y-1 py-1 sm:ml-[-1.5rem] sm:pl-[1.5rem] cursor-grab active:cursor-grabbing"
      data-day-expense-id={@day_expense.id}
    >
      <.inline class="2xl:text-lg">
        <span>{@day_expense.name}</span>
        <.money_display
          money={@day_expense.expense.price}
          display_currency={@display_currency}
          class="font-normal"
        />
        <.day_expense_button phx-click="edit" phx-target={@myself}>
          <.icon name="hero-pencil" class="h-4 w-4" />
        </.day_expense_button>
        <.day_expense_button
          phx-click="delete"
          phx-target={@myself}
          data-confirm={
            gettext("Are you sure you want to delete expense \"%{name}\"?", name: @day_expense.name)
          }
        >
          <.icon name="hero-trash" class="h-4 w-4" />
        </.day_expense_button>
      </.inline>
    </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign(:edit, true)

    {:noreply, socket}
  end

  def handle_event("delete", _, socket) do
    case Planning.delete_day_expense(socket.assigns.day_expense) do
      {:ok, _day_expense} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete expense"))}
    end
  end

  attr :rest, :global
  slot :inner_block, required: true

  defp day_expense_button(assigns) do
    ~H"""
    <span
      class="cursor-pointer hover:text-zinc-900 hover:dark:text-zinc-100"
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
