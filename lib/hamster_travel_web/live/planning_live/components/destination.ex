defmodule HamsterTravelWeb.Planning.Destination do
  @moduledoc """
  Live component responsible for showing and editing destinations (aka cities to visit)
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :destination, HamsterTravel.Planning.Destination, required: true

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.DestinationForm}
        id={"destination-form-#{@destination.id}"}
        destination={@destination}
        trip={@trip}
        action={:edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div>
      <.inline class="gap-[0px]">
        <.flag size={20} country={@destination.city.country_code} class="mr-2" />
        <span class="sm:grow">{Geo.city_name(@destination.city)}</span>
        <.icon_button size="xs" phx-click="edit" phx-target={@myself} class="justify-self-end ml-2">
          <.icon name="hero-pencil" class="w-4 h-4" />
        </.icon_button>
        <.icon_button
          class="justify-self-end"
          size="xs"
          phx-click="delete"
          phx-target={@myself}
          data-confirm={
            gettext("Are you sure you want to delete %{city_name} from your trip?",
              city_name: Geo.city_name(@destination.city)
            )
          }
        >
          <.icon name="hero-trash" class="w-4 h-4" />
        </.icon_button>
      </.inline>
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
    case Planning.delete_destination(socket.assigns.destination) do
      {:ok, _destination} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete destination"))}
    end
  end
end
