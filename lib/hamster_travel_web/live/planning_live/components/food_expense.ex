defmodule HamsterTravelWeb.Planning.FoodExpense do
  @moduledoc """
  Live component responsible for showing and editing food expense.
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning.{FoodExpense, Trip}

  attr(:food_expense, FoodExpense, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def render(%{edit: true} = assigns) do
    ~H"""
    <div id={"food-expense-#{@food_expense.id}"}>
      <.live_component
        module={HamsterTravelWeb.Planning.FoodExpenseForm}
        id={"food-expense-form-#{@food_expense.id}"}
        food_expense={@food_expense}
        trip={@trip}
        display_currency={@display_currency}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div id={"food-expense-#{@food_expense.id}"} class="flex flex-col gap-y-1 py-1">
      <.inline class="items-center gap-2 text-base font-medium flex-wrap">
        <span class="whitespace-nowrap">
          <.money_display
            money={@food_expense.price_per_day}
            display_currency={@display_currency}
            class="inline-flex"
          />
          {gettext("per day")}
          x {@food_expense.days_count} {ngettext("day", "days", @food_expense.days_count)}
          x {@food_expense.people_count} {ngettext("person", "people", @food_expense.people_count)}
        </span>
        <span class="whitespace-nowrap">
          =
          <.money_display
            money={@food_expense.expense.price}
            display_currency={@display_currency}
            class="inline-flex font-normal"
          />
        </span>
        <.food_expense_button phx-click="edit" phx-target={@myself}>
          <.icon name="hero-pencil" class="h-4 w-4" />
        </.food_expense_button>
      </.inline>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, edit: false)}
  end

  def handle_event("edit", _, socket) do
    {:noreply, assign(socket, :edit, true)}
  end

  attr :rest, :global
  slot :inner_block, required: true

  defp food_expense_button(assigns) do
    ~H"""
    <span class="cursor-pointer hover:text-zinc-900 hover:dark:text-zinc-100" {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
