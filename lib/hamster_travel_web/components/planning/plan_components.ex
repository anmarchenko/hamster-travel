defmodule HamsterTravelWeb.Planning.PlanComponents do
  @moduledoc """
  This component renders plan items/cards
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.{Avatar, Flags}

  def header(assigns) do
    ~H"""
      <div class="flex flex-col-reverse sm:flex-row">
        <div class="flex-1">
          <h1 class="text-xl font-semibold text-black dark:text-white"><%= @plan.name %></h1>
          <div class="text-zinc-600 flex flex-row gap-x-4 mt-4 dark:text-zinc-300">
            <UI.icon_text>
              <Icons.budget />
              <%= @plan.budget %> <%= @plan.currency_symbol %>
            </UI.icon_text>
            <UI.icon_text>
              <Icons.calendar />
              <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
            </UI.icon_text>
            <UI.icon_text>
              <Icons.user />
              <%= @plan.people_count %> <%= gettext("ppl") %>
            </UI.icon_text>
          </div>
          <div class="flex flex-row text-xs gap-x-4 sm:text-base mt-4 ">
            <UI.link url={plan_url(@plan.slug, :edit)}>
              <%= gettext("Edit plan") %>
            </UI.link>
            <UI.link url={plan_url(@plan.slug, :copy)}>
              <%= gettext("Make a copy") %>
            </UI.link>
            <UI.link url={plan_url(@plan.slug, :pdf)}%>
              <%= gettext("Export as PDF") %>
            </UI.link>
          </div>
          <div class="flex flex-row gap-x-3 mt-4">
            <.status_badge status={@plan.status} />
            <%= for country <- @plan.countries do %>
              <Flags.flag size={24} country={country} />
            <% end %>
            <Avatar.round user={@plan.author} size={:small} />
          </div>
        </div>
        <div class="">
          <img class="max-h-52 mb-4 sm:mb-0 sm:h-36 sm:w-auto sm:max-h-full shadow-lg rounded-md" src={@plan.cover} />
        </div>
      </div>
    """
  end

  def plan_tabs(assigns) do
    ~H"""
      <UI.tabs class="hidden sm:flex">
        <UI.tab url={plan_url(@plan.slug, :transfers)} active={@active_tab == "transfers"}>
          <UI.icon_text>
            <Icons.airplane />
            <%= gettext("Transfers and hotels") %>
          </UI.icon_text>
        </UI.tab>
        <UI.tab url={plan_url(@plan.slug, :activities)} active={@active_tab == "activities"}>
          <UI.icon_text>
            <Icons.pen />
            <%= gettext("Activities") %>
          </UI.icon_text>
        </UI.tab>
      </UI.tabs>
    """
  end

  def status_badge(assigns) do
    classes =
      class_list([
        {"flex items-center h-6 px-3 text-xs font-semibold rounded-full", true},
        {status_colors(assigns), true}
      ])

    ~H"""
      <span class={classes}>
        <%= Gettext.gettext(HamsterTravelWeb.Gettext, @status) %>
      </span>
    """
  end

  def plan_url(slug), do: "/plans/#{slug}"
  def plan_url(slug, :transfers), do: "/plans/#{slug}?tab=transfers"
  def plan_url(slug, :activities), do: "/plans/#{slug}?tab=activities"
  def plan_url(slug, :catering), do: "/plans/#{slug}?tab=catering"
  def plan_url(slug, :documents), do: "/plans/#{slug}?tab=documents"
  def plan_url(slug, :report), do: "/plans/#{slug}?tab=report"
  def plan_url(slug, :edit), do: "/plans/#{slug}/edit"
  def plan_url(slug, :pdf), do: "/plans/#{slug}/pdf"
  def plan_url(slug, :copy), do: "/plans/#{slug}/copy"

  defp status_colors(%{status: "finished"}),
    do: "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-100"

  defp status_colors(%{status: "planned"}),
    do: "text-yellow-500 bg-yellow-200 dark:bg-yellow-800 dark:text-yellow-200"

  defp status_colors(%{status: "draft"}),
    do: "text-pink-500 bg-pink-100 dark:bg-pink-800 dark:text-pink-100"
end
