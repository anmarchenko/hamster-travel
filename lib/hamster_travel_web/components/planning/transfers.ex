defmodule HamsterTravelWeb.Planning.Transfers do
  @moduledoc """
  Live component responsible for showing and editing transfers
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravelWeb.Planning.PlanComponents

  def update(%{plan: plan, day_index: day_index}, socket) do
    transfers = HamsterTravel.find_transfers_by_day(plan, day_index)

    socket =
      socket
      |> assign(transfers: transfers)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, transfers: transfers} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-8">
      <%= for transfer <- transfers do %>
        <div class="flex flex-col gap-y-2">
          <div class="flex flex-row gap-x-2 items-center text-zinc-400 dark:text-zinc-600">
            <PlanComponents.transfer_icon type={transfer.type} />
            <%= transfer.company %>
            <Icons.budget />
            <%= Formatter.format_money(transfer.price, transfer.price_currency) %>
          </div>
          <div class="flex flex-row text-lg">
            <div class="flex flex-col gap-y-2 pr-6 border-r-2 font-medium">
              <div><%= transfer.time_from %></div>
              <div><%= transfer.time_to %></div>
            </div>
            <div class="flex flex-col pl-6 gap-y-2">
              <div>
                <%= transfer.city_from.name %>
                <.station station={transfer.station_from} />
              </div>
              <div>
                <%= transfer.city_to.name %>
                <.station station={transfer.station_to} />
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp station(assigns) do
    if assigns.station do
      ~H"""
        (<%= @station %>)
      """
    else
      ~H"""
      """
    end
  end
end
