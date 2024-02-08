defmodule HamsterTravelWeb.Planning.Trips.Shorts do
  @moduledoc """
  Shorts stats about a trip (days, people, budget)
  """
  use HamsterTravelWeb, :html

  alias HamsterTravelWeb.CoreComponents

  import HamsterTravelWeb.Icons.Budget

  attr(:trip, :map, required: true)
  attr(:icon_class, :string, default: nil)
  attr(:class, :string, default: nil)

  def shorts(assigns) do
    ~H"""
    <.inline class={
      CoreComponents.build_class([
        "gap-4",
        @class
      ])
    }>
      <.inline class="gap-1">
        <.budget class={@icon_class} />
        <%= Formatter.format_money(0, @trip.currency) %>
      </.inline>
      <.inline class="gap-1">
        <.icon name={:calendar} outline={true} class={"h-4 w-4 #{@icon_class}"} />
        <%= @trip.duration %> <%= ngettext("day", "days", @trip.duration) %>
      </.inline>
      <.inline class="gap-1">
        <.icon name={:user} outline={true} class={"h-4 w-4 #{@icon_class}"} />
        <%= @trip.people_count %> <%= gettext("ppl") %>
      </.inline>
    </.inline>
    """
  end
end
