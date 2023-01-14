defmodule HamsterTravelWeb.Packing.BackpackList do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  require Logger

  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Card
  import HamsterTravelWeb.Inline
  import PhxComponentHelpers

  alias HamsterTravel.Packing

  alias HamsterTravelWeb.Packing.AddItem
  alias HamsterTravelWeb.Packing.BackpackItem

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:list])

    socket =
      socket
      |> assign(:edit, false)
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
            <.header edit={@edit} changeset={@changeset} list={@list} phx-target={@myself} />
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

  def header(%{edit: false} = assigns) do
    ~H"""
    <.inline>
      <div class="grow text-white dark:text-zinc-300"><%= @list.name %></div>
      <.ht_icon_button
        icon={:pencil}
        color="white"
        phx-click="edit"
        phx-target={assigns[:"phx-target"]}
      />
      <.ht_icon_button
        icon={:trash}
        color="white"
        phx-click="delete"
        phx-target={assigns[:"phx-target"]}
        data-confirm={gettext("Are you sure you want to delete this list? All items will be lost")}
      />
      <.ht_icon_button
        icon={:chevron_down}
        color="white"
        x-show="showItems"
        @click="showItems = !showItems"
      />
      <.ht_icon_button
        icon={:chevron_right}
        color="white"
        x-show="!showItems"
        @click="showItems = !showItems"
      />
    </.inline>
    """
  end

  def header(%{edit: true} = assigns) do
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
          <.ht_icon_button icon={:check} color="white" />
        </.inline>
      </.form>
      <.ht_icon_button icon={:x} color="white" phx-click="cancel" phx-target={assigns[:"phx-target"]} />
    </.inline>
    """
  end

  defp decoration_classes(true), do: "bg-violet-500 dark:bg-violet-800 line-through"
  defp decoration_classes(_), do: "bg-violet-700 dark:bg-violet-900"
end
