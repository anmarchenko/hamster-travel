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

  def handle_event("edit", _, socket) do
    item = socket.assigns.item

    socket =
      socket
      |> assign(:edit, true)
      |> assign(:name, item.name <> " " <> Integer.to_string(item.count))

    {:noreply, socket}
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="mt-3">
      <.inline class="!gap gap-1">
        <.form :let={f} for={:item} class="grow mr-2" phx-change="checked_item" phx-target={@myself}>
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
        <.icon_button
          link_type="button"
          size="xs"
          color="gray"
          class="justify-self-end"
          phx-click="edit"
          phx-target={@myself}
        >
          <Heroicons.Outline.pencil class={
            PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
          } />
        </.icon_button>
        <.icon_button link_type="button" size="xs" color="gray" class="justify-self-end">
          <Heroicons.Outline.trash class={
            PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
          } />
        </.icon_button>
      </.inline>
    </div>
    """
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class="mt-3">
      <.inline>
        <.form
          :let={f}
          for={:edit_item}
          phx-submit="update_item"
          phx-change="change"
          phx-target={@myself}
          as={:item}
        >
          <.inline>
            <.text_input
              form={f}
              id={"update-item-#{@item.id}"}
              field={:name}
              placeholder={gettext("Add backpack item")}
              value={@name}
              autofocus
            />
            <.icon_button link_type="button" size="xs" color="gray">
              <Heroicons.Outline.check class={
                PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
              } />
            </.icon_button>
          </.inline>
        </.form>
        <.icon_button link_type="button" size="xs" color="gray">
          <Heroicons.Outline.x class={
            PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
          } />
        </.icon_button>
      </.inline>
    </div>
    """
  end
end
