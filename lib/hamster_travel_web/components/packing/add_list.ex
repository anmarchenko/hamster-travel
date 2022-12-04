defmodule HamsterTravelWeb.Packing.AddList do
  @moduledoc """
  Live component responsible for create a new backpack list
  """

  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Inline

  require Logger

  # alias HamsterTravel.Packing

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

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="mb-5">
      <.button color="secondary" phx-click="edit" phx-target={@myself}>
        <Heroicons.Solid.plus class="w-5 h-5 mr-2" />
        <%= gettext("Add list") %>
      </.button>
    </div>
    """
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class="mb-5">
      <.inline>
        here will be form
      </.inline>
    </div>
    """
  end
end
