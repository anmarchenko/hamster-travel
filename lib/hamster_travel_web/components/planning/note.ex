defmodule HamsterTravelWeb.Planning.Note do
  @moduledoc """
  Live component responsible for showing and editing day notes
  """
  use HamsterTravelWeb, :live_component

  def update(%{note: note}, socket) do
    socket =
      socket
      |> assign(note: note)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false, note: note} = assigns) do
    ~H"""
    <div>
      <UI.secondary_text>
        <%= note.text %>
      </UI.secondary_text>
    </div>
    """
  end
end
