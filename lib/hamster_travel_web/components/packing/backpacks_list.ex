defmodule HamsterTravelWeb.Packing.BackpacksList do
  @moduledoc """
  This component renders backpack items/cards
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.Packing.BackpackComponents

  def grid(assigns) do
    ~H"""
    <section class={"#{standard_container()} p-6 mt-6"}>
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <%= for backpack <- @backpacks do %>
          <.card backpack={backpack} />
        <% end %>
      </div>
    </section>
    """
  end

  def card(%{backpack: %{slug: slug}} = assigns) do
    link = BackpackComponents.backpack_url(slug)

    ~H"""
    <UI.card>
      <div class="p-4 flex flex-col gap-y-4">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <%= live_redirect to: link do %>
            <%= @backpack.name %>
          <% end %>
        </p>
        <div class="text-xs sm:text-base text-zinc-400 font-light flex flex-row gap-x-4 dark:text-zinc-500">
          <UI.icon_text>
            <Icons.calendar />
            <%= @backpack.duration %> <%= ngettext("day", "days", @backpack.duration) %>
          </UI.icon_text>
          <UI.icon_text>
            <Icons.user />
            <%= @backpack.people_count %> <%= gettext("ppl") %>
          </UI.icon_text>
        </div>
      </div>
    </UI.card>
    """
  end
end
