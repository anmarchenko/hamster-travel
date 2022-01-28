defmodule HamsterTravelWeb.Planning.Plan do
  @moduledoc """
  This component renders plan items/cards
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.{Avatar, Flags, Icons}

  def card(%{plan: %{slug: slug}} = assigns) do
    max_flags = 3
    plan_url = "/plans/#{slug}"

    ~H"""
      <div class="flex flex-row bg-zinc-50 dark:bg-zinc-900 dark:border dark:border-zinc-600 shadow-md rounded-lg hover:shadow-lg hover:bg-white hover:dark:bg-zinc-800 ">
        <div class="shrink-0">
          <%= live_redirect to: plan_url do %>
            <img src={@plan.cover} class="w-32 rounded-l-lg"/>
          <% end %>
        </div>
        <div class="flex-1 p-4 max-w-[calc(100%_-_theme(width.32))] flex flex-col justify-between">
          <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
            <%= live_redirect to: plan_url do %>
              <%= @plan.name %>
            <% end %>
          </p>
          <div class="text-zinc-400 font-light flex flex-row gap-x-4 dark:text-zinc-500">
            <.icon_text>
              <Icons.money_stack />
              <%= @plan.budget %> <%= @plan.currency_symbol %>
            </.icon_text>
            <.icon_text>
              <Icons.calendar />
              <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
            </.icon_text>
            <.icon_text>
              <Icons.user />
              <%= @plan.people_count %> <%= gettext("ppl") %>
            </.icon_text>
          </div>
          <div class="flex flex-row gap-x-3">
            <.status_badge status={@plan.status} />
            <%= for country <- Enum.take(@plan.countries, max_flags) do %>
              <Flags.flag size={24} country={country} />
            <% end %>
            <Avatar.round user={@plan.author} size={:small} />
          </div>
        </div>
      </div>
    """
  end

  defp icon_text(assigns) do
    ~H"""
      <div class="flex flex-row gap-x-2 items-center">
        <%= render_slot(@inner_block) %>
      </div>
    """
  end

  defp status_badge(assigns) do
    classes =
      class_list([
        "flex items-center h-6 px-3 text-xs font-semibold rounded-full",
        status_colors(assigns)
      ])

    ~H"""
      <span class={classes}>
        <%= Gettext.gettext(HamsterTravelWeb.Gettext, @status) %>
      </span>
    """
  end

  defp status_colors(%{status: "finished"}),
    do: "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-100"

  defp status_colors(%{status: "planned"}),
    do: "text-yellow-500 bg-yellow-200 dark:bg-yellow-800 dark:text-yellow-200"

  defp status_colors(%{status: "draft"}),
    do: "text-pink-500 bg-pink-100 dark:bg-pink-800 dark:text-pink-100"
end