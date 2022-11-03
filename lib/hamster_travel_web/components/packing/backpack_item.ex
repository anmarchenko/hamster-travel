defmodule HamsterTravelWeb.Packing.BackpackItem do
  @moduledoc """
  Live component responsible for showing and editing a single backpack item
  """

  use HamsterTravelWeb, :live_component

  require Logger

  alias HamsterTravel.Packing

  import PhxComponentHelpers

  import HamsterTravelWeb.Inline

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:item])

    {:ok, assign(socket, assigns)}
  end

  def handle_event("checked_item", %{"item" => %{"checked" => checked}}, socket) do
    case Packing.update_item_checked(socket.assigns.item, checked) do
      {:ok, item} ->
        socket =
          socket
          |> assign(:item, item)

        {:noreply, socket}

      {:error, error} ->
        Logger.error("Could not update item because of #{Kernel.inspect(error)}")

        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form :let={f} for={:item} phx-change="checked_item" phx-target={@myself}>
        <%= label class: "cursor-pointer" do %>
          <.inline>
            <.checkbox form={f} field={:checked} label={@item.name} value={@item.checked} />
            <div class="text-sm"><%= @item.name %> <%= @item.count %></div>
          </.inline>
        <% end %>
      </.form>
    </div>
    """
  end
end
