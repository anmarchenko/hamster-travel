defmodule HamsterTravelWeb.Planning.Note do
  @moduledoc """
  Live component responsible for showing and editing day notes
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Secondary

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
    <div class="text-sm">
      <.secondary>
        <%= note.text %>
      </.secondary>
    </div>
    """
  end
end
