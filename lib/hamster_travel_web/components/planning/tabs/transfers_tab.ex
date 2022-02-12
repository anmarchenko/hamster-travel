defmodule HamsterTravelWeb.Planning.Tabs.TransfersTab do
  @moduledoc """
  Transfers/hotels tab
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravelWeb.Planning.{Hotel, PlanComponents, Transfer}

  def update(%{plan: plan}, socket) do
    budget = HamsterTravel.fetch_budget(plan, :transfers)

    socket =
      socket
      |> assign(budget: budget)
      |> assign(plan: plan)
      |> assign(transfers: plan.transfers)
      |> assign(hotels: plan.hotels)
      |> assign(places: plan.places)

    {:ok, socket}
  end

  def transfers_list(%{transfers: transfers, day_index: day_index} = assigns) do
    case HamsterTravel.filter_transfers_by_day(transfers, day_index) do
      [] ->
        ~H"""
          <UI.secondary_text>
            <%= gettext("No transfers planned for this day") %>
          </UI.secondary_text>
        """

      transfers_for_day ->
        ~H"""
          <%= for transfer <- transfers_for_day  do %>
            <.live_component module={Transfer} id={"transfers-#{transfer.id}-day-#{day_index}"} transfer={transfer} day_index={day_index} />
          <% end %>
        """
    end
  end

  def hotels_list(%{hotels: hotels, day_index: day_index} = assigns) do
    case HamsterTravel.filter_hotels_by_day(hotels, day_index) do
      [] ->
        ~H"""
          <UI.secondary_text>
            <%= gettext("No hotels for this day") %>
          </UI.secondary_text>
        """

      hotels_for_day ->
        ~H"""
          <%= for hotel <- hotels_for_day  do %>
            <.live_component module={Hotel} id={"hotels-#{hotel.id}-day-#{day_index}"} hotel={hotel} day_index={day_index} />
          <% end %>
        """
    end
  end
end
