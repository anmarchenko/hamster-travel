defmodule HamsterTravelWeb.Planning.PlanCard do
  @moduledoc """
  Renders plan card for a list of plans
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.Flag
  import HamsterTravelWeb.Icons.Budget
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Secondary

  alias HamsterTravelWeb.Planning.PlanComponents

  def plan_card(assigns) do
    assigns
    |> set_attributes([], required: [:plan])
    |> render()
  end

  defp render(%{plan: %{slug: slug}} = assigns) do
    link = plan_url(slug)

    ~H"""
    <UI.card>
      <div class="shrink-0">
        <%= live_redirect to: link do %>
          <img src={@plan.cover} class="w-32 h-32 object-cover object-center rounded-l-lg" />
        <% end %>
      </div>
      <div class="p-4 max-w-[calc(100%_-_theme(width.32))] flex flex-col justify-between">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <%= live_redirect to: link do %>
            <%= @plan.name %>
          <% end %>
        </p>
        <.secondary tag="div" italic={false}>
          <div class="text-xs sm:text-base font-light flex flex-row gap-x-4">
            <.inline>
              <.budget class="hidden sm:block" />
              <%= Formatter.format_money(@plan.budget, @plan.currency) %>
            </.inline>
            <.inline>
              <Heroicons.Outline.calendar class="h-4 w-4 hidden sm:block" />
              <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
            </.inline>
            <.inline>
              <Heroicons.Outline.user class="h-4 w-4 hidden sm:block" />
              <%= @plan.people_count %> <%= gettext("ppl") %>
            </.inline>
          </div>
        </.secondary>
        <.inline class="gap-3">
          <PlanComponents.status_badge status={@plan.status} />
          <%= for country <- Enum.take(@plan.countries, 1) do %>
            <.flag size={24} country={country} />
          <% end %>
          <.avatar
            size="xs"
            src={@plan.author.avatar_url}
            name={@plan.author.name}
            random_color
            class="!w-6 !h-6"
          />
        </.inline>
      </div>
    </UI.card>
    """
  end
end
