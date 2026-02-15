defmodule HamsterTravelWeb.Planning.NoteForm do
  @moduledoc """
  Note create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning

  attr :action, :atom, required: true
  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, default: nil
  attr :on_finish, :fun, required: true
  attr :can_edit, :boolean, default: false

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id={"note-form-#{@id}"}
        for={@form}
        as={:note}
        phx-target={@myself}
        phx-submit="form_submit"
        class="space-y-4 max-w-2xl"
      >
        <.field
          field={@form[:title]}
          type="text"
          label={gettext("Note title")}
          wrapper_class="mb-0"
          placeholder={gettext("e.g. Food ideas")}
          required
        />

        <.formatted_text_area
          field={@form[:text]}
          label={gettext("Text")}
          wrapper_class="mb-0"
        />

        <div class="flex justify-between mt-2">
          <.button color="light" type="button" phx-click="cancel" phx-target={@myself}>
            {gettext("Cancel")}
          </.button>
          <.button color="primary" size="xs" type="submit">
            {gettext("Save")}
          </.button>
        </div>

        <.field field={@form[:day_index]} type="hidden" />
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset =
      case assigns.action do
        :new ->
          Planning.new_note(assigns.trip, assigns.day_index)

        :edit ->
          Planning.change_note(assigns.note)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"note" => note_params}, socket) do
    if socket.assigns.can_edit do
      on_submit(socket, socket.assigns.action, note_params)
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("cancel", _, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp on_submit(socket, :new, note_params) do
    socket.assigns.trip
    |> Planning.create_note(note_params)
    |> result(socket)
  end

  defp on_submit(socket, :edit, note_params) do
    socket.assigns.note
    |> Planning.update_note(note_params)
    |> result(socket)
  end

  defp result({:ok, _note}, socket) do
    socket.assigns.on_finish.()

    {:noreply, socket}
  end

  defp result({:error, changeset}, socket) do
    {:noreply, assign_form(socket, changeset)}
  end
end
