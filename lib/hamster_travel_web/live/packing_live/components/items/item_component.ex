defmodule HamsterTravelWeb.Packing.Items.ItemComponent do
  @moduledoc """
  Live component responsible for showing and editing a single backpack item
  """

  use HamsterTravelWeb, :live_component

  require Logger

  alias HamsterTravel.Packing

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def handle_event("check", %{"checked" => checked}, socket) do
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

  def handle_event("update", params, socket) do
    item_to_update = socket.assigns.item

    case Packing.update_item(item_to_update, params) do
      {:ok, item} ->
        socket =
          socket
          |> assign(:item, item)
          |> assign(:edit, false)

        {:noreply, socket}

      {:error, error} ->
        Logger.warning(
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

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class="mt-1">
      <.inline>
        <.form :let={f} for={%{}} phx-submit="update" phx-target={@myself}>
          <.inline>
            <.text_input
              form={f}
              id={"update-item-#{@item.id}"}
              field={:name}
              placeholder={@name}
              value={@name}
              x-init="$el.focus()"
            />
            <.icon_button>
              <.icon name={:check} />
            </.icon_button>
          </.inline>
        </.form>
        <.icon_button phx-click="cancel" phx-target={@myself}>
          <.icon name={:x_mark} />
        </.icon_button>
      </.inline>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="mt-1">
      <.inline class="!gap gap-1">
        <.form :let={f} for={%{}} class="grow mr-2" phx-change="check" phx-target={@myself}>
          <label class="cursor-pointer">
            <.inline class={decoration_classes(@item.checked)}>
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
          </label>
        </.form>
        <.icon_button size="xs" class="justify-self-end" phx-click="edit" phx-target={@myself}>
          <.icon name={:pencil} class="w-5 h-5" />
        </.icon_button>
        <.icon_button size="xs" class="justify-self-end" phx-click="delete" phx-target={@myself}>
          <.icon name={:trash} class="w-5 h-5" />
        </.icon_button>
      </.inline>
    </div>
    """
  end

  defp decoration_classes(true), do: "line-through"
  defp decoration_classes(_), do: ""
end
