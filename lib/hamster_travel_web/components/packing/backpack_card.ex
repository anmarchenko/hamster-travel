defmodule HamsterTravelWeb.Packing.BackpackCard do
  @moduledoc """
  This component renders backpack card
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.Card
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Secondary

  def backpack_card(assigns) do
    assigns
    |> set_attributes([], required: [:backpack])
    |> render()
  end

  defp render(%{backpack: %{slug: slug}} = assigns) do
    link = backpack_url(slug)

    ~H"""
    <.card>
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
    </.card>
    """
  end
end
