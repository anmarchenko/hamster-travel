defmodule HamsterTravelWeb.Planning.FoodExpense do
  @moduledoc """
  Live component responsible for showing and editing food expense.
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning.{FoodExpense, Trip}

  attr(:food_expense, FoodExpense, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)
  attr(:can_edit, :boolean, default: false)

  def render(%{edit: true} = assigns) do
    ~H"""
    <div id={"food-expense-#{@food_expense.id}"}>
      <.live_component
        module={HamsterTravelWeb.Planning.FoodExpenseForm}
        id={"food-expense-form-#{@food_expense.id}"}
        food_expense={@food_expense}
        trip={@trip}
        display_currency={@display_currency}
        can_edit={@can_edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      id={"food-expense-#{@food_expense.id}"}
      class="flex w-full max-w-3xl flex-col gap-y-1 rounded-md py-1.5"
    >
      <.inline class="w-full gap-2 2xl:text-lg">
        <span class="flex min-w-0 flex-1 items-center gap-1.5">
          <span class="min-w-0 truncate">
            <.money_display
              money={@food_expense.price_per_day}
              display_currency={@display_currency}
              class="inline-flex"
            />
            {gettext("per day")} x {@food_expense.days_count} {ngettext(
              "day",
              "days",
              @food_expense.days_count
            )} x {@food_expense.people_count} {ngettext(
              "person",
              "people",
              @food_expense.people_count
            )}
          </span>
          <.edit_delete_buttons
            :if={@can_edit}
            class="shrink-0"
            edit_target={@myself}
            show_delete={false}
          />
        </span>
        <div class="ml-auto flex shrink-0 items-center justify-end sm:w-44">
          <.money_display
            money={@food_expense.expense.price}
            display_currency={@display_currency}
            class="text-right text-base font-normal tabular-nums text-zinc-500 dark:text-zinc-400 2xl:text-lg"
          />
        </div>
      </.inline>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, edit: false)}
  end

  def handle_event("edit", _, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :edit, true)}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
