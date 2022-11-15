defmodule HamsterTravelWeb.Packing.AddItem do
  @moduledoc """
  Live component responsible for create a new backpack item
  """

  use HamsterTravelWeb, :live_component

  import PhxComponentHelpers

  require Logger

  alias HamsterTravel.Packing

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:list])
      |> assign(changeset: Packing.new_item())

    {:ok, assign(socket, assigns)}
  end

  def handle_event("create_item", %{"backpack_item" => backpack_params}, socket) do
    Packing.create_item(backpack_params, socket.assigns.list)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form :let={f} for={:item} phx-submit="create_item" phx-target={@myself} as={:backpack_item}>
        <.form_field type="text_input" form={f} field={:name} placeholder={gettext("Backpack item")} />
      </.form>
    </div>
    """
  end
end
