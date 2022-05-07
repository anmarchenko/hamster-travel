defmodule HamsterTravelWeb.Planning.Transfer do
  @moduledoc """
  Live component responsible for showing and editing transfers
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Icons.Budget

  alias HamsterTravelWeb.Planning.PlanComponents

  def update(%{transfer: transfer}, socket) do
    socket =
      socket
      |> assign(transfer: transfer)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, transfer: transfer} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1">
      <div class="flex flex-row gap-2 items-center text-zinc-400 dark:text-zinc-500">
        <PlanComponents.transfer_icon type={transfer.type} />
        <%= transfer.vehicle_id %>
        <%= transfer.company %>
        <.budget />
        <%= Formatter.format_money(transfer.price, transfer.price_currency) %>
      </div>
      <div class="flex flex-row text-lg mt-2">
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

      <UI.secondary_text>
        <%= transfer.comment %>
      </UI.secondary_text>

      <UI.external_links links={transfer.links} />
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
