defmodule HamsterTravelWeb.Planning.Note do
  @moduledoc """
  Live component responsible for showing and editing notes.
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{Note, Trip}

  attr(:note, Note, required: true)
  attr(:trip, Trip, required: true)

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class="max-w-2xl">
      <.live_component
        module={HamsterTravelWeb.Planning.NoteForm}
        id={"note-form-#{@note.id}"}
        note={@note}
        trip={@trip}
        day_index={@note.day_index}
        action={:edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      class="draggable-note flex flex-col gap-y-2 py-1 sm:ml-[-1.5rem] sm:pl-[1.5rem] sm:hover:bg-zinc-100 sm:dark:hover:bg-zinc-700 cursor-grab active:cursor-grabbing"
      data-note-id={@note.id}
    >
      <.inline class="2xl:text-lg">
        <span
          class="cursor-pointer"
          phx-click={
            JS.toggle(
              to: "#note-content-#{@note.id}",
              in: {"transition-opacity duration-300", "opacity-0", "opacity-100"},
              out: {"transition-opacity duration-300", "opacity-100", "opacity-0"}
            )
          }
        >
          {@note.title}
        </span>
        <.edit_delete_buttons
          class="ml-1"
          edit_target={@myself}
          delete_target={@myself}
          delete_confirm={
            gettext("Are you sure you want to delete note \"%{title}\"?", title: @note.title)
          }
        />
      </.inline>
      <div id={"note-content-#{@note.id}"} class="hidden flex flex-col gap-y-1">
        <.formatted_text :if={@note.text} text={@note.text} class="mt-1" />
      </div>
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
    {:noreply, assign(socket, :edit, true)}
  end

  def handle_event("delete", _, socket) do
    case Planning.delete_note(socket.assigns.note) do
      {:ok, _note} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete note"))}
    end
  end
end
