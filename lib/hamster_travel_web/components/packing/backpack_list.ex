defmodule HamsterTravelWeb.Packing.BackpackList do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  import HamsterTravelWeb.Card

  alias HamsterTravelWeb.Packing.AddItem
  alias HamsterTravelWeb.Packing.BackpackItem

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:list])

    {:ok, assign(socket, assigns)}
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
            <.live_component module={AddItem} id={"item-add-#{@list.id}"} list={@list} />
          </div>
        </div>
      </.card>
    </span>
    """
  end
end
