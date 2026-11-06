defmodule HamsterTravelWeb.Planning.NoteNew do
  @moduledoc """
  Button to add a new note.
  """
  use HamsterTravelWeb, :live_component

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :edit, :boolean, default: false
  attr :can_edit, :boolean, default: false

  @impl true
  def render(%{edit: true} = assigns) do
    ~H"""
    <div
      id={@id}
      class="w-full max-w-3xl rounded-xl border border-zinc-200 bg-white p-4 sm:p-6 dark:border-zinc-700 dark:bg-zinc-900"
    >
      <.live_component
        module={HamsterTravelWeb.Planning.NoteForm}
        id={"new-#{@id}"}
        trip={@trip}
        action={:new}
        can_edit={@can_edit}
        on_finish={fn -> send(self(), {:finish_adding, "note"}) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="flex justify-start">
      <.button
        :if={@can_edit}
        color="primary"
        size="sm"
        type="button"
        phx-click="add_note"
        phx-target={@myself}
      >
        <.icon_text icon="hero-plus" label={gettext("Add note")} />
      </.button>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("add_note", _, socket) do
    if socket.assigns.can_edit do
      send(self(), {:start_adding, "note", socket.assigns.id})
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
