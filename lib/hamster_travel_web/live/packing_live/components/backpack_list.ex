defmodule HamsterTravelWeb.Packing.BackpackList do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  require Logger

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Packing

  alias HamsterTravelWeb.Packing.AddItem
  alias HamsterTravelWeb.Packing.BackpackItem

  @button_color "text-white dark:text-zinc-400 hover:bg-primary-600 dark:hover:bg-primary-800"

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:done, Packing.all_checked?(assigns.list.items))
      |> assign(:changeset, Packing.change_list(assigns.list))
      |> assign(assigns)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    list = socket.assigns.list

    socket =
      socket
      |> assign(:edit, true)
      |> assign(:changeset, Packing.change_list(list))

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket =
      socket
      |> assign(:edit, false)

    {:noreply, socket}
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
        Logger.warn(
          "Could not update an list #{list_to_update.id} because of #{Kernel.inspect(error)}"
        )

        socket =
          socket
          |> assign(:edit, false)

        {:noreply, socket}
    end
  end

  def handle_event("delete", _, socket) do
    Packing.delete_list(socket.assigns.list)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.card>
        <div
          class="flex flex-col w-full"
          x-data={"{ showItems: $persist(true).as('list-#{@list.id}') }"}
        >
          <div class={"p-4 rounded-t-lg #{decoration_classes(@done)}"}>
            <.card_header edit={@edit} changeset={@changeset} list={@list} phx-target={@myself} />
          </div>
          <div class="p-4" x-show="showItems" x-transition.duration.300ms>
            <.live_component
              :for={item <- @list.items}
              module={BackpackItem}
              id={"item-#{item.id}"}
              item={item}
            />
            <.live_component module={AddItem} id={"item-add-#{@list.id}"} list={@list} />
          </div>
        </div>
      </.card>
    </div>
    """
  end

  attr :edit, :boolean, required: true
  attr :list, :any, required: true
  attr :"phx-target", :any, required: true
  attr :changeset, :any, default: nil

  def card_header(%{edit: false} = assigns) do
    ~H"""
    <.inline>
      <div class="grow text-white dark:text-zinc-300"><%= @list.name %></div>
      <.icon_button
        size="xs"
        class={button_color()}
        phx-click="edit"
        phx-target={assigns[:"phx-target"]}
      >
        <.icon name={:pencil} />
      </.icon_button>
      <.icon_button
        size="xs"
        class={button_color()}
        phx-click="delete"
        phx-target={assigns[:"phx-target"]}
        data-confirm={gettext("Are you sure you want to delete this list? All items will be lost")}
      >
        <.icon name={:trash} />
      </.icon_button>
      <.icon_button
        size="xs"
        class={button_color()}
        x-show="showItems"
        @click="showItems = !showItems"
      >
        <.icon name={:chevron_down} />
      </.icon_button>

      <.icon_button
        size="xs"
        class={button_color()}
        x-show="!showItems"
        @click="showItems = !showItems"
      >
        <.icon name={:chevron_right} />
      </.icon_button>
    </.inline>
    """
  end

  def card_header(%{edit: true} = assigns) do
    ~H"""
    <.inline>
      <.form
        :let={f}
        for={@changeset}
        phx-submit="update"
        phx-target={assigns[:"phx-target"]}
        as={:list}
      >
        <.inline>
          <.text_input form={f} id={"update-item-#{@list.id}"} field={:name} x-init="$el.focus()" />
          <.icon_button class={button_color()}>
            <.icon name={:check} />
          </.icon_button>
        </.inline>
      </.form>
      <.icon_button class={button_color()} phx-click="cancel" phx-target={assigns[:"phx-target"]}>
        <.icon name={:x_mark} />
      </.icon_button>
    </.inline>
    """
  end

  defp decoration_classes(true), do: "bg-violet-500 dark:bg-violet-800 line-through"
  defp decoration_classes(_), do: "bg-violet-700 dark:bg-violet-900"

  defp button_color, do: @button_color
end
