defmodule HamsterTravelWeb.Packing.BackpacksList do
  @moduledoc """
  This component renders backpack items/cards
  """
  use HamsterTravelWeb, :component

  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Secondary

  alias HamsterTravelWeb.Packing.BackpackComponents

  def grid(assigns) do
    ~H"""
    <section class={"#{standard_container()} p-6 mt-6"}>
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <%= for backpack <- @backpacks do %>
          <.backpack_card backpack={backpack} />
        <% end %>
      </div>
    </section>
    """
  end

  def backpack_card(%{backpack: %{slug: slug}} = assigns) do
    link = BackpackComponents.backpack_url(slug)

    ~H"""
    <UI.card>
      <div class="p-4 flex flex-col gap-y-4">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <%= live_redirect to: link do %>
            <%= @backpack.name %>
          <% end %>
        </p>

        <.secondary tag="div" italic={false}>
          <div class="text-xs sm:text-base font-light flex flex-row gap-x-2">
            <.inline>
              <Heroicons.Outline.calendar class="h-4 w-4" />
              <%= @backpack.duration %> <%= ngettext("day", "days", @backpack.duration) %>
            </.inline>
            <.inline>
              <Heroicons.Outline.user class="h-4 w-4" />
              <%= @backpack.people_count %> <%= gettext("ppl") %>
            </.inline>
          </div>
        </.secondary>
      </div>
    </UI.card>
    """
  end
end
