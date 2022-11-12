defmodule HamsterTravelWeb.Packing.BackpackItem do
  @moduledoc """
  Live component responsible for showing and editing a single backpack item
  """

  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Inline
  import PhxComponentHelpers

  require Logger

  alias HamsterTravel.Packing

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:item])

    {:ok, assign(socket, assigns)}
  end

  def handle_event("checked_item", %{"item" => %{"checked" => checked}}, socket) do
    item_to_update = socket.assigns.item

    case Packing.update_item_checked(item_to_update, checked) do
      {:ok, item} ->
        socket =
          socket
          |> assign(:item, item)

        {:noreply, socket}

      {:error, error} ->
        Logger.error(
          "Could not update an item #{item_to_update.id} because of #{Kernel.inspect(error)}"
        )

        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form :let={f} for={:item} phx-change="checked_item" phx-target={@myself}>
        <%= label class: "cursor-pointer" do %>
          <.inline>
            <.checkbox
              form={f}
              id={"item-#{@item.id}"}
              field={:checked}
              label={@item.name}
              value={@item.checked}
            />
            <div class="text-sm"><%= @item.name %> <%= @item.count %></div>
          </.inline>
        <% end %>
      </.form>
    </div>
    """
  end
end
