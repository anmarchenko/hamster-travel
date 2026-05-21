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
      class={[
        "flex w-full max-w-3xl flex-col gap-y-1 rounded-md py-1.5",
        @can_edit && "draggable-day-expense cursor-grab active:cursor-grabbing"
      ]}
      data-day-expense-id={@day_expense.id}
    >
      <.inline class="w-full gap-2 2xl:text-lg">
        <span class="flex min-w-0 flex-1 items-center gap-1.5">
          <span class="min-w-0 truncate">{@day_expense.name}</span>
          <.link
            :if={@day_expense.link}
            href={@day_expense.link}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={gettext("Open expense link")}
            title={gettext("Open expense link")}
            class="inline-flex h-5 w-5 shrink-0 items-center justify-center rounded text-zinc-400 transition-colors hover:text-violet-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 dark:text-zinc-500 dark:hover:text-violet-300"
          >
            <.icon name="hero-link" class="h-4 w-4" />
          </.link>
        </span>
        <div class="ml-auto flex shrink-0 items-center justify-end gap-2 sm:w-44">
          <.money_display
            money={@day_expense.expense.price}
            display_currency={@display_currency}
            class="text-right text-base font-normal tabular-nums text-zinc-500 dark:text-zinc-400 2xl:text-lg"
          />
          <.edit_delete_buttons
            :if={@can_edit}
            class="shrink-0"
            edit_target={@myself}
            delete_target={@myself}
            delete_confirm={
              gettext(
                "Are you sure you want to delete expense \"%{name}\"?",
                name: @day_expense.name
              )
            }
          />
        </div>
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
