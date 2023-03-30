defmodule HamsterTravelWeb.Planning.PlanShorts do
  @moduledoc """
  Shorts stats about a plan (days, people, budget)
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.CoreComponents

  import HamsterTravelWeb.Icons.Budget

  attr(:plan, :map, required: true)
  attr(:icon_class, :string, default: nil)
  attr(:class, :string, default: nil)

  def plan_shorts(assigns) do
    ~H"""
    <.inline class={
      CoreComponents.build_class([
        "gap-4",
        @class
      ])
    }>
      <.inline class="gap-1">
        <.budget class={@icon_class} />
        <%= Formatter.format_money(@plan.budget, @plan.currency) %>
      </.inline>
      <.inline class="gap-1">
        <.icon name={:calendar} outline={true} class={"h-4 w-4 #{@icon_class}"} />
        <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
      </.inline>
      <.inline class="gap-1">
        <.icon name={:user} outline={true} class={"h-4 w-4 #{@icon_class}"} />
        <%= @plan.people_count %> <%= gettext("ppl") %>
      </.inline>
    </.inline>
    """
  end
end
