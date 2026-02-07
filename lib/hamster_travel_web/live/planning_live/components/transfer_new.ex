defmodule HamsterTravelWeb.Planning.TransferNew do
  @moduledoc """
  Live component responsible for creating a new transfer
  """

  use HamsterTravelWeb, :live_component

  attr :id, :string, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :current_user, HamsterTravel.Accounts.User, default: nil
  attr :day_index, :integer, required: true
  attr :class, :string, default: nil
  attr :edit, :boolean, default: false

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class={@class}>
      <.live_component
        module={HamsterTravelWeb.Planning.TransferForm}
        id={"new-#{@id}"}
        trip={@trip}
        current_user={@current_user}
        day_index={@day_index}
        action={:new}
        on_finish={fn -> send(self(), {:finish_adding, "transfer"}) end}
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
          {gettext("Add transfer")}
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
    send(self(), {:start_adding, "transfer", socket.assigns.id})
    {:noreply, socket}
  end
end
