defmodule HamsterTravelWeb.Planning.Tabs.TransfersTab do
  @moduledoc """
  Transfers/hotels tab
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravelWeb.Planning.{Hotel, Place, PlanComponents, Transfer}

  def update(%{plan: plan}, socket) do
    budget = HamsterTravel.fetch_budget(plan, :transfers)

    socket =
      socket
      |> assign(budget: budget)
      |> assign(plan: plan)

    {:ok, socket}
  end
end
