defmodule HamsterTravelWeb.Planning.Transfer do
  @moduledoc """
  Live component responsible for showing and editing transfers
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{Transfer, Trip}
  alias HamsterTravelWeb.Cldr, as: Formatters

  import HamsterTravelWeb.Icons.{Airplane, Bus, Car, Ship, Taxi, Train}

  attr(:transfer, Transfer, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.TransferForm}
        id={"transfer-form-#{@transfer.id}"}
        transfer={@transfer}
        trip={@trip}
        action={:edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      class="draggable-transfer flex flex-col gap-y-1 cursor-grab hover:bg-gray-50 dark:hover:bg-gray-800 rounded p-2 transition-colors duration-200 active:cursor-grabbing"
      data-transfer-id={@transfer.id}
    >
      <.inline>
        <.transfer_icon type={@transfer.transport_mode} />
        {@transfer.vessel_number}
        {@transfer.carrier}
        <.money_display money={@transfer.expense.price} display_currency={@display_currency} />
        <.edit_delete_buttons
          class="ml-auto"
          edit_target={@myself}
          delete_target={@myself}
          delete_confirm={gettext("Are you sure you want to delete this transfer from your trip?")}
        />
      </.inline>
      <div class="flex flex-row text-lg mt-2 mb-2">
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

      <.note :if={formatted_text_present?(@transfer.note)}>
        <.formatted_text text={@transfer.note} />
      </.note>
    </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign(:edit, true)

    {:noreply, socket}
  end

  def handle_event("delete", _, socket) do
    case Planning.delete_transfer(socket.assigns.transfer) do
      {:ok, _transfer} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete transfer"))}
    end
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
