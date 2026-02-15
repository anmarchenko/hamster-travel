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
  attr(:can_edit, :boolean, default: false)

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
        can_edit={@can_edit}
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
        <.edit_delete_buttons
          :if={@can_edit}
          class="ml-1"
          edit_target={@myself}
          delete_target={@myself}
          delete_confirm={
            gettext("Are you sure you want to delete expense \"%{name}\"?", name: @day_expense.name)
          }
        />
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
    if socket.assigns.can_edit do
      socket =
        socket
        |> assign(:edit, true)

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_day_expense(socket.assigns.day_expense) do
        {:ok, _day_expense} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, gettext("Failed to delete expense"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
