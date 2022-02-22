defmodule HamsterTravelWeb.Planning.PlansList do
  @moduledoc """
  This component renders plan items/cards
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.Avatar
  alias HamsterTravelWeb.Planning.PlanComponents

  def grid(assigns) do
    ~H"""
      <div class="grid grid-cols-1 xl:grid-cols-2 2xl:grid-cols-3 gap-8">
        <%= for plan <- @plans do %>
          <.card plan={plan} />
        <% end %>
      </div>
    """
  end

  def card(%{plan: %{slug: slug}} = assigns) do
    link = PlanComponents.plan_url(slug)

    ~H"""
      <div class={"flex flex-row #{card_styles()}"}>
        <div class="shrink-0">
          <%= live_redirect to: link do %>
            <img src={@plan.cover} class="w-32 h-32 object-cover object-center rounded-l-lg"/>
          <% end %>
        </div>
        <div class="p-4 max-w-[calc(100%_-_theme(width.32))] flex flex-col justify-between">
          <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
            <%= live_redirect to: link do %>
              <%= @plan.name %>
            <% end %>
          </p>
          <div class="text-xs sm:text-base text-zinc-400 font-light flex flex-row gap-x-4 dark:text-zinc-500">
            <UI.icon_text>
              <Icons.budget class="hidden sm:block" />
              <%= Formatter.format_money(@plan.budget, @plan.currency) %>
            </UI.icon_text>
            <UI.icon_text>
              <Icons.calendar class="hidden sm:block" />
              <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
            </UI.icon_text>
            <UI.icon_text>
              <Icons.user class="hidden sm:block" />
              <%= @plan.people_count %> <%= gettext("ppl") %>
            </UI.icon_text>
          </div>
          <div class="flex flex-row gap-x-3">
            <PlanComponents.status_badge status={@plan.status} />
            <%= for country <- Enum.take(@plan.countries, 1) do %>
              <Flags.flag size={24} country={country} />
            <% end %>
            <Avatar.round user={@plan.author} size={:small} />
          </div>
        </div>
      </div>
    """
  end
end
