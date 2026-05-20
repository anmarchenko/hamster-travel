defmodule HamsterTravelWeb.Planning.AccommodationNew do
  @moduledoc """
  Live component responsible for creating a new accommodation
  """

  use HamsterTravelWeb, :live_component

  attr :id, :string, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, required: true
  attr :class, :string, default: nil
  attr :edit, :boolean, default: false
  attr :can_edit, :boolean, default: false

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class={@class}>
      <.live_component
        module={HamsterTravelWeb.Planning.AccommodationForm}
        id={"new-#{@id}"}
        trip={@trip}
        day_index={@day_index}
        action={:new}
        can_edit={@can_edit}
        on_finish={fn -> send(self(), {:finish_adding, "accommodation"}) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <a
        :if={@can_edit}
        href="#"
        phx-click="start_adding"
        phx-target={@myself}
        class="inline-flex py-0.5 text-sm font-normal text-zinc-400 transition-colors hover:text-primary-600 focus-visible:text-primary-600 focus-visible:outline-none dark:text-zinc-500 dark:hover:text-primary-300 dark:focus-visible:text-primary-300"
      >
        <.inline class="gap-1.5">
          <.icon name="hero-plus-solid" class="h-4 w-4" />
          {gettext("Add accommodation")}
        </.inline>
      </a>
    </div>
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  def handle_event("start_adding", _, socket) do
    if socket.assigns.can_edit do
      send(self(), {:start_adding, "accommodation", socket.assigns.id})
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
