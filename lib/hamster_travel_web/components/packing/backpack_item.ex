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

    socket = socket |> assign(assigns) |> assign(:edit, false)

    {:ok, socket}
  end

  def handle_event("check", %{"item" => %{"checked" => checked}}, socket) do
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

  def handle_event("edit", _, socket) do
    item = socket.assigns.item

    socket =
      socket
      |> assign(:edit, true)
      |> assign(:name, Packing.format_item(item))

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket =
      socket
      |> assign(:edit, false)

    {:noreply, socket}
  end

  def handle_event("update", %{"item" => params}, socket) do
    item_to_update = socket.assigns.item

    case Packing.update_item(item_to_update, params) do
      {:ok, item} ->
        socket =
          socket
          |> assign(:item, item)
          |> assign(:edit, false)

        {:noreply, socket}

      {:error, error} ->
        Logger.warn(
          "Could not update an item #{item_to_update.id} because of #{Kernel.inspect(error)}"
        )

        socket =
          socket
          |> assign(:edit, false)

        {:noreply, socket}
    end
  end

  def handle_event("delete", _, socket) do
    Packing.delete_item(socket.assigns.item)
    {:noreply, socket}
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="mt-3">
      <.inline class="!gap gap-1">
        <.form :let={f} for={:item} class="grow mr-2" phx-change="check" phx-target={@myself}>
          <%= label class: "cursor-pointer" do %>
            <.inline>
              <.checkbox
                form={f}
                id={"item-#{@item.id}"}
                field={:checked}
                label={@item.name}
                value={@item.checked}
              />
              <div class="text-sm grow"><%= @item.name %></div>
              <div class="text-sm justify-self-end"><%= @item.count %></div>
            </.inline>
          <% end %>
        </.form>
        <.ht_icon_button
          icon={:pencil}
          class="justify-self-end"
          phx-click="edit"
          phx-target={@myself}
        />
        <.ht_icon_button
          icon={:trash}
          class="justify-self-end"
          phx-click="delete"
          phx-target={@myself}
        />
      </.inline>
    </div>
    """
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class="mt-3">
      <.inline>
        <.form :let={f} for={:item} phx-submit="update" phx-target={@myself}>
          <.inline>
            <.text_input
              form={f}
              id={"update-item-#{@item.id}"}
              field={:name}
              placeholder={@name}
              value={@name}
              x-init="$el.focus()"
            />
            <.ht_icon_button icon={:check} />
          </.inline>
        </.form>
        <.ht_icon_button icon={:x} phx-click="cancel" phx-target={@myself} />
      </.inline>
    </div>
    """
  end
end
