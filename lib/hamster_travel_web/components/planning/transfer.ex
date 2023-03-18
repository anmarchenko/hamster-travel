defmodule HamsterTravelWeb.Planning.Transfer do
  @moduledoc """
  Live component responsible for showing and editing transfers
  """
  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  import HamsterTravelWeb.Icons.{Airplane, Budget, Bus, Car, Ship, Taxi, Train}
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Secondary

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([edit: false], required: [:transfer])

    {:ok, assign(socket, assigns)}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1">
      <.secondary italic={false} tag="div">
        <.inline>
          <.transfer_icon type={@transfer.type} />
          <%= @transfer.vehicle_id %>
          <%= @transfer.company %>
          <.budget />
          <%= Formatter.format_money(@transfer.price, @transfer.price_currency) %>
        </.inline>
      </.secondary>
      <div class="flex flex-row text-lg mt-2">
        <div class="flex flex-col gap-y-2 pr-6 border-r-2 font-medium">
          <div><%= @transfer.time_from %></div>
          <div><%= @transfer.time_to %></div>
        </div>
        <div class="flex flex-col pl-6 gap-y-2">
          <div>
            <%= @transfer.city_from.name %>
            <.station station={@transfer.station_from} />
          </div>
          <div>
            <%= @transfer.city_to.name %>
            <.station station={@transfer.station_to} />
          </div>
        </div>
      </div>

      <.secondary>
        <%= @transfer.comment %>
      </.secondary>

      <.external_links links={@transfer.links} />
    </div>
    """
  end

  def transfer_icon(%{type: "plane"} = assigns) do
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

  def transfer_icon(%{type: "ship"} = assigns) do
    ~H"""
    <.ship />
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
