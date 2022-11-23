defmodule HamsterTravelWeb.Packing.BackpackList do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  import HamsterTravelWeb.Card
  import HamsterTravelWeb.Inline

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

  def render(%{edit: false} = assigns) do
    ~H"""
    <span>
      <.card>
        <div class="flex flex-col w-full">
          <div class="p-4 bg-violet-700 dark:bg-violet-900 text-white dark:text-zinc-400 rounded-t-lg">
            <.inline>
              <div class="grow"><%= @list.name %></div>
              <.ht_icon_button color="info" click="edit" target={@myself}>
                <Heroicons.Outline.pencil class={
                  PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
                } />
              </.ht_icon_button>
              <.ht_icon_button color="info" click="delete" target={@myself}>
                <Heroicons.Outline.trash class={
                  PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
                } />
              </.ht_icon_button>
            </.inline>
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

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>
      <.card>
        <div class="flex flex-col w-full">
          <div class="p-4 bg-violet-700 dark:bg-violet-900 text-white dark:text-zinc-400 rounded-t-lg">
            <.inline>
              <.form :let={f} for={@changeset} phx-submit="update" phx-target={@myself} as={:list}>
                <.inline>
                  <.text_input
                    form={f}
                    id={"update-item-#{@list.id}"}
                    field={:name}
                    x-init="$el.focus()"
                  />
                  <.ht_icon_button>
                    <Heroicons.Outline.check
                      color="info"
                      class={PetalComponents.Button.get_icon_button_spinner_size_classes("xs")}
                    />
                  </.ht_icon_button>
                </.inline>
              </.form>
              <.ht_icon_button color="info" click="cancel" target={@myself}>
                <Heroicons.Outline.x class={
                  PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
                } />
              </.ht_icon_button>
            </.inline>
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
end
