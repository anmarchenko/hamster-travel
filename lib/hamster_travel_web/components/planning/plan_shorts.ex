defmodule HamsterTravelWeb.Planning.PlanShorts do
  @moduledoc """
  Shorts stats about a plan (days, people, budget)
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.Icons.Budget
  import HamsterTravelWeb.Inline

  @default_class "gap-4"

  def plan_shorts(assigns) do
    assigns
    |> set_attributes([icon_class: ""], required: [:plan])
    |> extend_class(@default_class)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <.inline {@heex_class}>
      <.inline class="gap-1">
        <.budget class={@icon_class} />
        <%= Formatter.format_money(@plan.budget, @plan.currency) %>
      </.inline>
      <.inline class="gap-1">
        <Heroicons.Outline.calendar class={"h-4 w-4 #{@icon_class}"} />
        <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
      </.inline>
      <.inline class="gap-1">
        <Heroicons.Outline.user class={"h-4 w-4 #{@icon_class}"} />
        <%= @plan.people_count %> <%= gettext("ppl") %>
      </.inline>
    </.inline>
    """
  end
end
