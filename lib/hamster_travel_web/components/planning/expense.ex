defmodule HamsterTravelWeb.Planning.Expense do
  @moduledoc """
  Live component responsible for showing and editing expenses
  """
  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([edit: false], required: [:expense])

    {:ok, assign(socket, assigns)}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="flex flex-row gap-x-1 text-sm font-light">
      <%= @expense.name %>
      <%= Formatter.format_money(@expense.price, @expense.price_currency) %>
    </div>
    """
  end
end
