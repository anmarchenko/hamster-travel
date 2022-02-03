defmodule HamsterTravelWeb.Planning.Transfers do
  @moduledoc """
  Transfers/hotels tab
  """
  use HamsterTravelWeb, :live_component

  def update(%{plan: plan}, socket) do
    budget = HamsterTravel.fetch_budget(plan, :transfers)

    socket =
      socket
      |> assign(budget: budget)
      |> assign(plan: plan)

    {:ok, socket}
  end

  def day(%{index: index, start_date: start_date} = assigns) do
    if start_date != nil do
      ~H"""
        <%= Formatter.date_with_weekday(Date.add(start_date, index)) %>
      """
    else
      ~H"""
        <%= gettext("Day") %> <%= index + 1 %>
      """
    end
  end
end
