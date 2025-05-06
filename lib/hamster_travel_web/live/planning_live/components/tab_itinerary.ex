defmodule HamsterTravelWeb.Planning.TabItinerary do
  @moduledoc """
  Transfers/hotels tab (itinerary)
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Icons.Budget
  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Planning.{DestinationNew, Hotel, Transfer}

  def update(assigns, socket) do
    # budget = HamsterTravel.fetch_budget(plan, :transfers)
    trip = assigns.trip
    budget = 0

    socket =
      socket
      |> assign(assigns)
      |> assign(
        budget: budget,
        destinations: trip.destinations,
        transfers: [],
        hotels: []
      )

    {:ok, socket}
  end

  def transfers(%{transfers: []} = assigns) do
    ~H"""
    <.secondary class="sm:hidden">
      {gettext("No transfers planned for this day")}
    </.secondary>
    """
  end

  def transfers(assigns) do
    ~H"""
    <.live_component
      :for={transfer <- @transfers}
      module={Transfer}
      id={"transfers-#{transfer.id}-day-#{@day_index}"}
      transfer={transfer}
    />
    """
  end

  def hotels(%{hotels: []} = assigns) do
    ~H"""
    <.secondary class="sm:hidden">
      {gettext("No hotels for this day")}
    </.secondary>
    """
  end

  def hotels(assigns) do
    ~H"""
    <.live_component
      :for={hotel <- @hotels}
      module={Hotel}
      id={"hotels-#{hotel.id}-day-#{@day_index}"}
      hotel={hotel}
    />
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row gap-x-4 mt-4 sm:mt-8 text-xl">
        <.inline>
          <.budget />
          {Formatter.format_money(@budget, @trip.currency)}
        </.inline>
      </div>

      <table class="sm:mt-8 sm:table-auto sm:border-collapse sm:border sm:border-slate-500 sm:w-full">
        <thead>
          <tr class="hidden sm:table-row">
            <th class="border border-slate-600 px-2 py-4 text-left w-1/12">{gettext("Day")}</th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/6">
              {gettext("Places")}
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">
              {gettext("Transfers")}
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">{gettext("Hotel")}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={i <- 0..(@trip.duration - 1)}
            class="flex flex-col gap-y-6 mt-10 sm:table-row sm:gap-y-0 sm:mt-0"
          >
            <td class="text-xl font-bold sm:font-normal sm:text-base sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <.day_label day_index={i} start_date={@trip.start_date} />
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col">
                <.destinations_list
                  trip={@trip}
                  destinations={Planning.destinations_for_day(i, @destinations)}
                  day_index={i}
                />
                <.live_component
                  module={DestinationNew}
                  id={"destination-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                />
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-8">
                <.transfers
                  transfers={HamsterTravel.filter_transfers_by_day(@transfers, i)}
                  day_index={i}
                />
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-8">
                <.hotels hotels={HamsterTravel.filter_hotels_by_day(@hotels, i)} day_index={i} />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
