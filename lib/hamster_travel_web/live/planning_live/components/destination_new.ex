defmodule HamsterTravelWeb.Planning.DestinationNew do
  @moduledoc """
  Live component responsible for creating a new destination
  """

  use HamsterTravelWeb, :live_component

  attr :day_index, :integer, required: true

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.DestinationForm}
        id={"destination-form-#{@id}"}
        trip={@trip}
        day_index={@day_index}
        action={:new}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <a
        href="#"
        phx-click="edit"
        phx-target={@myself}
        class="text-sm text-primary-500 hover:text-primary-800 dark:text-primary-500 dark:hover:text-primary-300"
      >
        <.inline>
          <.icon name="hero-plus-solid" class="w-5 h-5" />
          {gettext("Add destination")}
        </.inline>
      </a>
    </div>
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(edit: false)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign(:edit, true)

    {:noreply, socket}
  end

  def handle_event("finish", _, socket) do
    socket =
      socket
      |> assign(:edit, false)

    {:noreply, socket}
  end
end
