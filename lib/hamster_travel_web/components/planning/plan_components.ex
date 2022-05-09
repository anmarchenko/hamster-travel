defmodule HamsterTravelWeb.Planning.PlanComponents do
  @moduledoc """
  This component renders plan items/cards
  """
  use HamsterTravelWeb, :component

  import HamsterTravelWeb.Flag
  import HamsterTravelWeb.Icons.{Airplane, Budget, Bus, Car, Ship, Taxi, Train}
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Link

  alias HamsterTravelWeb.Planning.Place

  def header(assigns) do
    ~H"""
    <div class="flex flex-col-reverse sm:flex-row">
      <div class="flex-1">
        <h1 class="text-xl font-semibold text-black dark:text-white"><%= @plan.name %></h1>
        <div class="text-zinc-600 flex flex-row gap-x-4 mt-4 dark:text-zinc-300">
          <.inline>
            <.budget />
            <%= Formatter.format_money(@plan.budget, @plan.currency) %>
          </.inline>
          <.inline>
            <Heroicons.Outline.calendar class="h-4 w-4" />
            <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
          </.inline>
          <.inline>
            <Heroicons.Outline.user class="h-4 w-4" />
            <%= @plan.people_count %> <%= gettext("ppl") %>
          </.inline>
        </div>
        <div class="flex flex-row text-xs gap-x-4 sm:text-base mt-4 ">
          <.link to={plan_url(@plan.slug, :edit)} label={gettext("Edit plan")} />
          <.link to={plan_url(@plan.slug, :copy)} label={gettext("Make a copy")} />
          <.link to={plan_url(@plan.slug, :pdf)} label={gettext("Export as PDF")} />
          <.link to={plan_url(@plan.slug, :delete)} label={gettext("Delete")} />
        </div>
        <.inline class="gap-3 mt-4">
          <.status_badge status={@plan.status} />
          <%= for country <- @plan.countries do %>
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
      <div class="">
        <img
          class="max-h-52 mb-4 sm:mb-0 sm:h-36 sm:w-auto sm:max-h-full shadow-lg rounded-md"
          src={@plan.cover}
        />
      </div>
    </div>
    """
  end

  def status_badge(assigns) do
    classes =
      class_list([
        {assigns[:class], true},
        {"flex items-center h-6 px-3 text-xs font-semibold rounded-full", true},
        {status_colors(assigns), true}
      ])

    ~H"""
    <span class={classes}>
      <%= Gettext.gettext(HamsterTravelWeb.Gettext, @status) %>
    </span>
    """
  end

  def places_list(%{places: places, day_index: day_index} = assigns) do
    places_for_day = HamsterTravel.filter_places_by_day(places, day_index)

    ~H"""
    <%= for place <- places_for_day do %>
      <.live_component
        module={Place}
        id={"places-#{place.id}-day-#{day_index}"}
        place={place}
        day_index={day_index}
      />
    <% end %>
    """
  end

  def transfer_icon(%{type: "plane"} = assigns) do
    ~H"""
    <.airplane />
    """
  end

  def transfer_icon(%{type: "car"} = assigns) do
    ~H"""
    <.car />
    """
  end

  def transfer_icon(%{type: "taxi"} = assigns) do
    ~H"""
    <.taxi />
    """
  end

  def transfer_icon(%{type: "bus"} = assigns) do
    ~H"""
    <.bus />
    """
  end

  def transfer_icon(%{type: "train"} = assigns) do
    ~H"""
    <.train />
    """
  end

  def transfer_icon(%{type: "ship"} = assigns) do
    ~H"""
    <.ship />
    """
  end

  def day(%{index: index, start_date: start_date} = assigns) do
    if start_date != nil do
      ~H"""
      <%= Formatter.date_with_weekday(Date.add(start_date, index)) %>
      """
    else
      ~H"""
      <%= gettext("Day") %> <%= index + 1 %>
      """
    end
  end

  defp status_colors(%{status: "finished"}),
    do: "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-100"

  defp status_colors(%{status: "planned"}),
    do: "text-yellow-500 bg-yellow-200 dark:bg-yellow-800 dark:text-yellow-200"

  defp status_colors(%{status: "draft"}),
    do: "text-pink-500 bg-pink-100 dark:bg-pink-800 dark:text-pink-100"
end
