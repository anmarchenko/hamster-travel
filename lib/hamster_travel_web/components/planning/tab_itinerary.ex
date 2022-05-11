defmodule HamsterTravelWeb.Planning.TabItinerary do
  @moduledoc """
  Transfers/hotels tab (itinerary)
  """
  use HamsterTravelWeb, :live_component

  import PhxComponentHelpers

  import HamsterTravelWeb.Icons.Budget
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Planning.{DayLabel, PlacesList}
  import HamsterTravelWeb.Secondary

  alias HamsterTravelWeb.Planning.{Hotel, Transfer}

  def update(assigns, socket) do
    plan = assigns[:plan]
    budget = HamsterTravel.fetch_budget(plan, :transfers)

    assigns =
      assigns
      |> set_attributes(
        [
          budget: budget,
          places: plan.places,
          transfers: plan.transfers,
          hotels: plan.hotels
        ],
        required: [:plan]
      )

    {:ok, assign(socket, assigns)}
  end

  def places(%{places: places, day_index: day_index} = assigns) do
    places_for_day = HamsterTravel.filter_places_by_day(places, day_index)

    ~H"""
    <.places_list places={places_for_day} day_index={day_index} />
    """
  end

  def transfers(%{transfers: transfers, day_index: day_index} = assigns) do
    case HamsterTravel.filter_transfers_by_day(transfers, day_index) do
      [] ->
        ~H"""
        <.secondary class="sm:hidden">
          <%= gettext("No transfers planned for this day") %>
        </.secondary>
        """

      transfers_for_day ->
        ~H"""
        <%= for transfer <- transfers_for_day  do %>
          <.live_component
            module={Transfer}
            id={"transfers-#{transfer.id}-day-#{day_index}"}
            transfer={transfer}
            day_index={day_index}
          />
        <% end %>
        """
    end
  end

  def hotels(%{hotels: hotels, day_index: day_index} = assigns) do
    case HamsterTravel.filter_hotels_by_day(hotels, day_index) do
      [] ->
        ~H"""
        <.secondary class="sm:hidden">
          <%= gettext("No hotels for this day") %>
        </.secondary>
        """

      hotels_for_day ->
        ~H"""
        <%= for hotel <- hotels_for_day  do %>
          <.live_component
            module={Hotel}
            id={"hotels-#{hotel.id}-day-#{day_index}"}
            hotel={hotel}
            day_index={day_index}
          />
        <% end %>
        """
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row gap-x-4 mt-4 sm:mt-8 text-xl">
        <.inline>
          <.budget />
          <%= Formatter.format_money(@budget, @plan.currency) %>
        </.inline>
      </div>

      <table class="sm:mt-8 sm:table-auto sm:border-collapse sm:border sm:border-slate-500 sm:w-full">
        <thead>
          <tr class="hidden sm:table-row">
            <th class="border border-slate-600 px-2 py-4 text-left w-1/12"><%= gettext("Day") %></th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/6">
              <%= gettext("Places") %>
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">
              <%= gettext("Transfers") %>
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3"><%= gettext("Hotel") %></th>
          </tr>
        </thead>
        <tbody>
          <%= for i <- 0..@plan.duration-1 do %>
            <tr class="flex flex-col gap-y-6 mt-10 sm:table-row sm:gap-y-0 sm:mt-0">
              <td class="text-xl font-bold sm:font-normal sm:text-base sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
                <.day_label index={i} start_date={@plan.start_date} />
              </td>
              <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
                <div class="flex flex-col gap-y-2">
                  <.places places={@places} day_index={i} />
                </div>
              </td>
              <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
                <div class="flex flex-col gap-y-8">
                  <.transfers transfers={@transfers} day_index={i} />
                </div>
              </td>
              <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
                <div class="flex flex-col gap-y-8">
                  <.hotels hotels={@hotels} day_index={i} />
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
