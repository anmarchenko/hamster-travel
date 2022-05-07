defmodule HamsterTravelWeb.Packing.List do
  @moduledoc """
  Live component responsible for showing and editing packing list
  """

  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Inline

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
          <div class="p-4">
            <.form let={f} for={:items}>
              <%= for item <- @list.items do %>
                <div class="mt-3">
                  <%= label class: "cursor-pointer" do %>
                    <.inline>
                      <.checkbox
                        form={f}
                        field={:"item-#{item.id}"}
                        label={item.name}
                        value={item.checked}
                      />
                      <div class="text-sm"><%= item.name %></div>
                    </.inline>
                  <% end %>
                </div>
              <% end %>
            </.form>
          </div>
        </div>
      </UI.card>
    </span>
    """
  end
end
