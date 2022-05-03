defmodule HamsterTravelWeb.Packing.List do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  use HamsterTravelWeb, :live_component

  def update(%{list: list}, socket) do
    socket =
      socket
      |> assign(list: list)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <span>
        <UI.card>
          <div class="flex flex-col w-full">
            <div class="p-4 bg-violet-700 dark:bg-violet-900 text-white dark:text-zinc-400 rounded-t-lg">
              <%= @list.name %>
            </div>
            <div class="px-4 py-2">
              <%= for item <- @list.items do %>
                <div class="mt-2">
                  <%= label class: "cursor-pointer inline-flex items-center block gap-2" do %>
                    <%= checkbox(:items, "item-#{item.id}", value: item.checked, class: "text-violet-700 border-gray-300 rounded w-5 h-5 ease-linear transition-all duration-150 dark:bg-gray-800 dark:border-gray-300") %>
                    <div class="text-sm block"><%= item.name %></div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </UI.card>
      </span>
    """
  end
end
