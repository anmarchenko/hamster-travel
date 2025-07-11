defmodule HamsterTravelWeb.Planning.Transfer do
  @moduledoc """
  Live component responsible for showing and editing transfers
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning.{Transfer, Trip}
  alias HamsterTravelWeb.Cldr, as: Formatters

  import HamsterTravelWeb.Icons.{Airplane, Bus, Car, Ship, Taxi, Train}

  attr(:transfer, Transfer, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1">
      <.inline>
        <.transfer_icon type={@transfer.transport_mode} />
        {@transfer.vessel_number}
        {@transfer.carrier}
        <.money_display money={@transfer.expense.price} display_currency={@display_currency} />
      </.inline>
      <div class="flex flex-row text-lg mt-2">
        <div class="flex flex-col gap-y-2 pr-6 border-r-2 font-medium">
          <div>{Formatters.format_time(@transfer.departure_time)}</div>
          <div>{Formatters.format_time(@transfer.arrival_time)}</div>
        </div>
        <div class="flex flex-col pl-6 gap-y-2">
          <div>
            {Geo.city_name(@transfer.departure_city)}
            <.station station={@transfer.departure_station} />
          </div>
          <div>
            {Geo.city_name(@transfer.arrival_city)}
            <.station station={@transfer.arrival_station} />
          </div>
        </div>
      </div>

      <.secondary>
        {@transfer.note}
      </.secondary>
    </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def transfer_icon(%{type: "flight"} = assigns) do
    ~H"""
    <.airplane />
    """
  end

  def transfer_icon(%{type: "car"} = assigns) do
    ~H"""
    <.car />
    """
  end

  def transfer_icon(%{type: "taxi"} = assigns) do
    ~H"""
    <.taxi />
    """
  end

  def transfer_icon(%{type: "bus"} = assigns) do
    ~H"""
    <.bus />
    """
  end

  def transfer_icon(%{type: "train"} = assigns) do
    ~H"""
    <.train />
    """
  end

  def transfer_icon(%{type: "boat"} = assigns) do
    ~H"""
    <.ship />
    """
  end

  defp station(assigns) do
    if assigns.station do
      ~H"""
      ({@station})
      """
    else
      ~H"""
      """
    end
  end
end
