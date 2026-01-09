defmodule HamsterTravelWeb.Planning.NoteNew do
  @moduledoc """
  Button to add a new note.
  """
  use HamsterTravelWeb, :live_component

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, default: nil
  attr :edit, :boolean, default: false
  attr :class, :string, default: nil

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.live_component
        module={HamsterTravelWeb.Planning.NoteForm}
        id={"new-#{@id}"}
        trip={@trip}
        day_index={@day_index}
        action={:new}
        on_finish={fn -> send(self(), {:finish_adding, "note"}) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <a
        href="#"
        phx-click="add_note"
        phx-target={@myself}
        class="text-sm text-primary-500 hover:text-primary-800 dark:text-primary-500 dark:hover:text-primary-300"
      >
        <.inline>
          <.icon name="hero-plus-solid" class="w-5 h-5" />
          {gettext("Add note")}
        </.inline>
      </a>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("add_note", _, socket) do
    send(self(), {:start_adding, "note", socket.assigns.id})
    {:noreply, socket}
  end
end
