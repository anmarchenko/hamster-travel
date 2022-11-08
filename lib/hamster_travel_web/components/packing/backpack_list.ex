defmodule HamsterTravelWeb.Packing.BackpackList do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  import HamsterTravelWeb.Card

  alias HamsterTravel.Packing.List

  alias HamsterTravelWeb.Packing.BackpackItem

  @topic "backpack_list"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, @topic)
    end

    {:ok, socket}
  end

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:list])

    {:ok, assign(socket, assigns)}
  end

  def handle_info({[:item, :updated], %{list_id: list_id, result: updated_item}}, socket) do
    list = socket.assigns.list

    if list.id != list_id do
      {:noreply, socket}
    else
      updated_items =
        list.items
        |> Enum.map(fn item ->
          if item.id == updated_item.id do
            updated_item
          else
            item
          end
        end)

      {:noreply, assign(socket, :list, %List{list | items: updated_items})}
    end
  end

  def render(assigns) do
    ~H"""
    <span>
      <.card>
        <div class="flex flex-col w-full">
          <div class="p-4 bg-violet-700 dark:bg-violet-900 text-white dark:text-zinc-400 rounded-t-lg">
            <%= @list.name %>
          </div>
          <div class="p-4">
            <.live_component
              :for={item <- @list.items}
              module={BackpackItem}
              id={"item-#{item.id}"}
              item={item}
            />
          </div>
        </div>
      </.card>
    </span>
    """
  end
end
