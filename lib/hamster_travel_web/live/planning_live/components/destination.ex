defmodule HamsterTravelWeb.Planning.Destination do
  @moduledoc """
  Live component responsible for showing and editing destinations (aka cities to visit)
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :destination, HamsterTravel.Planning.Destination, required: true
  attr :can_edit, :boolean, default: false

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.DestinationForm}
        id={"destination-form-#{@destination.id}"}
        destination={@destination}
        trip={@trip}
        action={:edit}
        can_edit={@can_edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div>
      <.inline class="gap-0">
        <.flag size={20} country={@destination.city.country_code} class="mr-2" />
        <span class="sm:grow">{Geo.city_name(@destination.city)}</span>
        <.edit_delete_buttons
          :if={@can_edit}
          class="ml-1"
          edit_target={@myself}
          delete_target={@myself}
          delete_confirm={
            gettext("Are you sure you want to delete %{city_name} from your trip?",
              city_name: Geo.city_name(@destination.city)
            )
          }
        />
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
    if socket.assigns.can_edit do
      socket =
        socket
        |> assign(:edit, true)

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_destination(socket.assigns.destination) do
        {:ok, _destination} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, gettext("Failed to delete destination"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
