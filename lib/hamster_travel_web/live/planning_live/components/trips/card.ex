defmodule HamsterTravelWeb.Planning.Trips.Card do
  @moduledoc """
  Renders plan card for a list of plans
  """
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Planning.Trips.Shorts
  import HamsterTravelWeb.Planning.Trips.StatusRow

  alias HamsterTravelWeb.Cldr

  attr(:trip, :map, required: true)

  def trip_card(assigns) do
    ~H"""
    <.card>
      <div class="shrink-0">
        <.link navigate={trip_url(@trip.slug)}>
          <img
            src={@trip[:cover] || placeholder_image(@trip.id)}
            class="w-32 h-32 object-cover object-center rounded-l-lg"
          />
        </.link>
      </div>
      <div class="p-4 max-w-[calc(100%_-_theme(width.32))] flex flex-col justify-between">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <.link navigate={trip_url(@trip.slug)}>
            <%= @trip.name %>
            <span class="font-light text-zinc-600 dark:text-zinc-400">
              <%= Cldr.year_with_month(@trip.start_date) %>
            </span>
          </.link>
        </p>
        <.secondary tag="div" italic={false} class="font-light">
          <.shorts trip={@trip} class="text-sm sm:text-base" icon_class="hidden sm:block" />
        </.secondary>
        <.status_row trip={@trip} flags_limit={1} />
      </div>
    </.card>
    """
  end
end
