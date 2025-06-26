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

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class={@class}>
      <.live_component
        module={HamsterTravelWeb.Planning.AccommodationForm}
        id={"new-#{@id}"}
        trip={@trip}
        day_index={@day_index}
        action={:new}
        on_finish={fn -> send(self(), {:finish_adding, "accommodation"}) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <a
        href="#"
        phx-click="start_adding"
        phx-target={@myself}
        class="text-sm text-primary-500 hover:text-primary-800 dark:text-primary-500 dark:hover:text-primary-300"
      >
        <.inline>
          <.icon name="hero-plus-solid" class="w-5 h-5" />
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
    send(self(), {:start_adding, "accommodation", socket.assigns.id})
    {:noreply, socket}
  end
end
