defmodule HamsterTravelWeb.Planning.Tabs.ActivitiesTab do
  @moduledoc """
  Activities tab
  """
  use HamsterTravelWeb, :live_component

  def update(%{plan: plan}, socket) do
    budget = HamsterTravel.fetch_budget(plan, :activities)

    socket =
      socket
      |> assign(budget: budget)
      |> assign(plan: plan)

    {:ok, socket}
  end
end
