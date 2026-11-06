defmodule HamsterTravelWeb.Planning.Note do
  @moduledoc """
  Note preview, reader, and editor.
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{Note, Trip}

  attr(:note, Note, required: true)
  attr(:trip, Trip, required: true)
  attr(:can_edit, :boolean, default: false)
  attr(:edit, :boolean, default: false)
  attr(:reading, :boolean, default: false)
  attr(:notes_path, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <article
      id={@id}
      class={[
        @reading && "flex flex-col gap-5",
        !@reading &&
          "min-w-0 rounded-xl border border-zinc-200 border-l-4 border-l-primary-300 bg-white shadow-sm dark:border-zinc-700 dark:border-l-primary-700 dark:bg-zinc-900",
        @can_edit && !@reading && "draggable-note"
      ]}
      data-note-id={@note.id}
    >
      <nav
        :if={@reading}
        class="flex items-center justify-between gap-4"
        aria-label={gettext("Notes")}
      >
        <.link
          id={"back-#{@id}"}
          patch={@notes_path}
          class="inline-flex items-center gap-2 rounded-md py-2 text-sm font-medium text-zinc-500 transition hover:text-primary-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-primary-500 dark:text-zinc-400 dark:hover:text-primary-300"
        >
          <.icon name="hero-arrow-left" class="h-4 w-4" />
          {gettext("Back to notes")}
        </.link>
        <div :if={@can_edit && !@edit} class="flex items-center gap-3">
          <.button
            color="light"
            size="sm"
            phx-click="edit"
            phx-target={@myself}
            aria-label={gettext("Edit")}
          >
            <.icon_text icon="hero-pencil" label={gettext("Edit")} />
          </.button>
          <.icon_button
            color="gray"
            size="sm"
            phx-click="delete"
            phx-target={@myself}
            aria-label={gettext("Delete")}
            title={gettext("Delete")}
            data-confirm={
              gettext("Are you sure you want to delete note \"%{title}\"?", title: @note.title)
            }
          >
            <.icon name="hero-trash" class="h-4 w-4" />
          </.icon_button>
        </div>
      </nav>

      <div
        :if={@edit}
        class={[
          "p-4 sm:p-6",
          @reading &&
            "rounded-xl border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-900"
        ]}
      >
        <.live_component
          module={HamsterTravelWeb.Planning.NoteForm}
          id={"edit-#{@id}"}
          note={@note}
          trip={@trip}
          action={:edit}
          can_edit={@can_edit}
          on_finish={fn -> send(self(), :close_form) end}
        />
      </div>

      <div :if={!@edit && !@reading} class="flex items-start gap-1 p-2 sm:gap-2 sm:p-3">
        <span
          :if={@can_edit && length(@trip.notes) > 1}
          data-note-drag-handle
          aria-hidden="true"
          class="mt-2 flex h-8 w-5 shrink-0 cursor-grab items-center justify-center text-zinc-400 active:cursor-grabbing dark:text-zinc-500"
        >
          <.icon name="hero-bars-3" class="h-4 w-4" />
        </span>
        <.link
          id={"open-#{@id}"}
          patch={"#{@notes_path}&note=#{@note.id}"}
          class="group min-w-0 flex-1 rounded-lg px-2 py-2 text-left transition hover:bg-zinc-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-primary-500 sm:px-3 dark:hover:bg-zinc-800"
        >
          <span class="flex items-start gap-2">
            <span class="min-w-0 flex-1 break-words text-lg font-semibold leading-snug tracking-tight text-zinc-900 sm:text-xl dark:text-zinc-100">
              {@note.title}
            </span>
            <.icon
              name="hero-chevron-right"
              class="mt-1 h-4 w-4 shrink-0 text-zinc-400 group-hover:text-primary-600 dark:group-hover:text-primary-300"
            />
          </span>
          <span
            :if={@preview != ""}
            class="mt-1.5 line-clamp-3 break-words text-sm leading-relaxed text-zinc-600 dark:text-zinc-300"
          >
            {@preview}
          </span>
        </.link>
        <.edit_delete_buttons
          :if={@can_edit}
          class="mt-2.5"
          edit_target={@myself}
          delete_target={@myself}
          delete_confirm={
            gettext("Are you sure you want to delete note \"%{title}\"?", title: @note.title)
          }
        />
      </div>

      <div
        :if={@reading && !@edit}
        id={"read-#{@id}"}
        phx-mounted={JS.focus(to: "#read-#{@id}-title")}
        class="overflow-hidden rounded-xl border border-zinc-200 bg-white dark:border-zinc-700 dark:bg-zinc-900"
      >
        <header class="border-b border-zinc-100 px-5 py-7 sm:px-9 sm:py-9 dark:border-zinc-800">
          <div class="mb-5 h-1 w-10 rounded-full bg-primary-400 dark:bg-primary-500"></div>
          <h2
            id={"read-#{@id}-title"}
            tabindex="-1"
            class="break-words text-3xl font-semibold leading-tight tracking-tight text-zinc-900 outline-none sm:text-4xl dark:text-zinc-100"
          >
            {@note.title}
          </h2>
        </header>
        <div class="px-5 py-6 sm:px-9 sm:py-8">
          <.formatted_text
            text={@note.text}
            class="break-words !space-y-4 !text-base !leading-relaxed text-zinc-700 dark:text-zinc-200 [&_pre]:overflow-x-auto"
          />
        </div>
      </div>
    </article>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      if socket.assigns[:note] && socket.assigns.note.text == assigns.note.text do
        socket
      else
        assign(socket, preview: text_preview(assigns.note.text))
      end

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("edit", _, socket) do
    if socket.assigns.can_edit do
      send(self(), {:open_form, "edit", "note", socket.assigns.note.id})
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_note(socket.assigns.note) do
        {:ok, _note} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete note"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  defp text_preview(nil), do: ""

  defp text_preview(text) do
    preview =
      text
      |> String.replace(~r/\s+/u, " ")
      |> String.replace(~r{</(?:p|div|li|blockquote|pre|h[1-6])\s*>|<br\b[^>]*>}i, "\\0 ")
      |> HtmlSanitizeEx.strip_tags()
      |> HtmlSanitizeEx.Parser.parse()
      |> List.wrap()
      |> Enum.join()
      |> String.replace(~r/\s+/u, " ")
      |> String.trim()

    case String.split_at(preview, 280) do
      {preview, ""} -> preview
      {preview, _rest} -> preview <> "…"
    end
  end
end
