defmodule HamsterTravelWeb.Packing.List do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  require Logger

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Packing

  alias HamsterTravelWeb.Packing.Item
  alias HamsterTravelWeb.Packing.ItemNew

  @button_color "text-white dark:text-zinc-400 hover:bg-primary-600 dark:hover:bg-primary-800"

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    changeset = Packing.change_list(assigns.list)

    socket =
      socket
      |> assign(assigns)
      |> assign(:done, Packing.all_checked?(assigns.list.items))
      |> assign_form(changeset)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    {:noreply, assign(socket, :edit, true)}
  end

  def handle_event("cancel", _, socket) do
    {:noreply, assign(socket, :edit, false)}
  end

  def handle_event("update", %{"list" => params}, socket) do
    list_to_update = socket.assigns.list

    case Packing.update_list(list_to_update, params) do
      {:ok, list} ->
        socket =
          socket
          |> assign(:list, list)
          |> assign(:edit, false)

        {:noreply, socket}

      {:error, error} ->
        Logger.warning(
          "Could not update an list #{list_to_update.id} because of #{Kernel.inspect(error)}"
        )

        {:noreply, assign(socket, :edit, false)}
    end
  end

  def handle_event("delete", _, socket) do
    Packing.delete_list(socket.assigns.list)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="draggable-list" data-list-id={@list.id}>
      <.card hover={false} class="overflow-hidden">
        <div
          class="flex w-full flex-col text-sm"
          x-data={"{ showItems: $persist(true).as('list-#{@list.id}') }"}
        >
          <div class={
            "draggable-list-handle cursor-grab p-2 active:cursor-grabbing #{decoration_classes(@done)}"
          }>
            <.card_header edit={@edit} form={@form} list={@list} phx-target={@myself} />
          </div>
          <div
            class="min-h-10 p-1"
            x-show="showItems"
            x-transition.duration.300ms
            data-packing-drop-zone
            data-target-list-id={@list.id}
          >
            <.live_component
              :for={item <- @list.items}
              module={Item}
              id={"item-#{item.id}"}
              item={item}
            />
            <.live_component module={ItemNew} id={"item-add-#{@list.id}"} list={@list} />
          </div>
        </div>
      </.card>
    </div>
    """
  end

  attr :edit, :boolean, required: true
  attr :list, :any, required: true
  attr :form, :any, required: true
  attr :"phx-target", :any, required: true
  attr :changeset, :any, default: nil

  def card_header(%{edit: false} = assigns) do
    ~H"""
    <.inline class="gap-1">
      <div class="min-w-0 grow text-sm leading-5 text-white dark:text-zinc-300">{@list.name}</div>
      <.icon_button
        size="xs"
        class={"!h-7 !w-7 !p-1.5 #{button_color()}"}
        phx-click="edit"
        phx-target={assigns[:"phx-target"]}
        aria-label={gettext("Edit")}
      >
        <.icon name="hero-pencil" class="h-4 w-4" />
      </.icon_button>
      <.icon_button
        size="xs"
        class={"!h-7 !w-7 !p-1.5 #{button_color()}"}
        phx-click="delete"
        phx-target={assigns[:"phx-target"]}
        data-confirm={gettext("Are you sure you want to delete this list? All items will be lost")}
        aria-label={gettext("Delete")}
      >
        <.icon name="hero-trash" class="h-4 w-4" />
      </.icon_button>
      <span x-show="showItems" @click="showItems = !showItems">
        <.icon_button
          size="xs"
          class={"!h-7 !w-7 !p-1.5 #{button_color()}"}
          aria-label={gettext("Collapse")}
        >
          <.icon name="hero-chevron-down" class="h-4 w-4" />
        </.icon_button>
      </span>

      <span x-show="!showItems" @click="showItems = !showItems">
        <.icon_button
          size="xs"
          class={"!h-7 !w-7 !p-1.5 #{button_color()}"}
          aria-label={gettext("Expand")}
        >
          <.icon name="hero-chevron-right" class="h-4 w-4" />
        </.icon_button>
      </span>
    </.inline>
    """
  end

  def card_header(%{edit: true} = assigns) do
    ~H"""
    <.inline class="gap-1">
      <.form
        for={@form}
        class="min-w-0 grow"
        phx-submit="update"
        phx-target={assigns[:"phx-target"]}
        as={:list}
      >
        <.inline class="gap-1">
          <span class="inline-flex" x-init="$nextTick(() => $el.querySelector('input')?.focus())">
            <.input
              id={"update-item-#{@list.id}"}
              field={@form[:name]}
              class="!h-8 !px-2 !py-1 !text-xs"
            />
          </span>
          <.icon_button class={"!h-7 !w-7 !p-1.5 #{button_color()}"}>
            <.icon name="hero-check" class="h-4 w-4" />
          </.icon_button>
        </.inline>
      </.form>
      <.icon_button
        class={"!h-7 !w-7 !p-1.5 #{button_color()}"}
        phx-click="cancel"
        phx-target={assigns[:"phx-target"]}
      >
        <.icon name="hero-x-mark" class="h-4 w-4" />
      </.icon_button>
    </.inline>
    """
  end

  defp decoration_classes(true), do: "bg-violet-500 dark:bg-violet-800 line-through"
  defp decoration_classes(_), do: "bg-violet-700 dark:bg-violet-900"

  defp button_color, do: @button_color

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
