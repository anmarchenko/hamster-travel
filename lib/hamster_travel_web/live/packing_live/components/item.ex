defmodule HamsterTravelWeb.Packing.Item do
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
    <div class="mt-0.5">
      <.inline class="gap-1">
        <.form :let={f} for={%{}} class="min-w-0 grow" phx-submit="update" phx-target={@myself}>
          <.inline class="gap-1">
            <span class="inline-flex" x-init="$nextTick(() => $el.querySelector('input')?.focus())">
              <.text_input
                form={f}
                id={"update-item-#{@item.id}"}
                field={:name}
                placeholder={@name}
                value={@name}
                class="!h-8 !px-2 !py-1 !text-xs"
              />
            </span>
            <.icon_button size="xs" class="!h-7 !w-7 !p-1.5">
              <.icon name="hero-check" class="h-4 w-4" />
            </.icon_button>
          </.inline>
        </.form>
        <.icon_button size="xs" class="!h-7 !w-7 !p-1.5" phx-click="cancel" phx-target={@myself}>
          <.icon name="hero-x-mark" class="h-4 w-4" />
        </.icon_button>
      </.inline>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      class="draggable-item cursor-grab rounded px-1 transition-colors duration-200 hover:bg-gray-100 active:cursor-grabbing dark:hover:bg-gray-800"
      data-item-id={@item.id}
    >
      <.inline class="gap-0.5">
        <.form :let={f} for={%{}} class="min-w-0 grow" phx-change="check" phx-target={@myself}>
          <label class="block cursor-pointer rounded">
            <.inline class={"min-h-8 w-full gap-0.5 #{decoration_classes(@item.checked)}"}>
              <span
                class="flex h-8 w-8 shrink-0 items-center justify-center"
                data-checkbox-hit-target
              >
                <.checkbox
                  form={f}
                  id={"item-#{@item.id}"}
                  field={:checked}
                  label={@item.name}
                  value={@item.checked}
                  class="!h-4 !w-4"
                />
              </span>
              <div class="min-w-0 grow text-[13px] leading-4">{@item.name}</div>
              <div class="shrink-0 text-[13px] leading-4 tabular-nums">{@item.count}</div>
            </.inline>
          </label>
        </.form>
        <.icon_button
          size="xs"
          class="!h-7 !w-7 !p-1.5"
          phx-click="edit"
          phx-target={@myself}
          aria-label={gettext("Edit")}
        >
          <.icon name="hero-pencil" class="h-4 w-4" />
        </.icon_button>
        <.icon_button
          size="xs"
          class="!h-7 !w-7 !p-1.5"
          phx-click="delete"
          phx-target={@myself}
          aria-label={gettext("Delete")}
        >
          <.icon name="hero-trash" class="h-4 w-4" />
        </.icon_button>
      </.inline>
    </div>
    """
  end

  defp decoration_classes(true), do: "line-through"
  defp decoration_classes(_), do: ""
end
