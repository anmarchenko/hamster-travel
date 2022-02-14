defmodule HamsterTravelWeb.Planning.Expense do
  @moduledoc """
  Live component responsible for showing and editing expenses
  """
  use HamsterTravelWeb, :live_component

  def update(%{expense: expense}, socket) do
    socket =
      socket
      |> assign(expense: expense)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, expense: expense} = assigns) do
    ~H"""
    <div class="flex flex-row gap-x-1 text-sm font-light">
      <%= expense.name %>
      <%= Formatter.format_money(expense.price, expense.price_currency) %>
    </div>
    """
  end
end
