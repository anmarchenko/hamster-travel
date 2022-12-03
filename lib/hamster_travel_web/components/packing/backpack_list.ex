defmodule HamsterTravelWeb.Packing.BackpackList do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

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

  def render(assigns) do
    ~H"""
    <span>
      <.card>
        <div class="flex flex-col w-full">
          <div class="p-4 bg-violet-700 dark:bg-violet-900 rounded-t-lg">
            <.header edit={@edit} changeset={@changeset} list={@list} phx-target={@myself} />
          </div>
          <div class="p-4">
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
    </span>
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
end
