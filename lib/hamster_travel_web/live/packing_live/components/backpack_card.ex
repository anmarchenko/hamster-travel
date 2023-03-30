defmodule HamsterTravelWeb.Packing.BackpackCard do
  @moduledoc """
  This component renders backpack card
  """
  use HamsterTravelWeb, :component

  attr(:backpack, HamsterTravel.Packing.Backpack, required: true)

  def backpack_card(assigns) do
    ~H"""
    <.card>
      <div class="p-4 flex flex-col gap-y-4">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <.link navigate={backpack_url(@backpack.slug)}>
            <%= @backpack.name %>
          </.link>
        </p>

        <.secondary tag="div" italic={false}>
          <div class="text-xs sm:text-base font-light flex flex-row gap-x-2">
            <.inline>
              <.icon name={:calendar} outline={true} class="h-4 w-4" />
              <%= @backpack.days %> <%= ngettext("day", "days", @backpack.days) %> / <%= @backpack.nights %> <%= ngettext(
                "night",
                "nights",
                @backpack.nights
              ) %>
            </.inline>
          </div>
        </.secondary>
      </div>
    </.card>
    """
  end
end
