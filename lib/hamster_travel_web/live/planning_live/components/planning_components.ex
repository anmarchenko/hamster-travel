defmodule HamsterTravelWeb.Planning.PlanningComponents do
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Icons.Budget

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Planning.TripCover
  alias HamsterTravelWeb.CoreComponents

  attr(:budget, Money, required: true)
  attr(:display_currency, :string, required: true)
  attr(:class, :string, default: nil)

  def budget_display(assigns) do
    ~H"""
    <.inline class={@class}>
      <.budget />
      <.money_display money={@budget} display_currency={@display_currency} />
    </.inline>
    """
  end

  attr(:trips, :list, required: true)
  attr(:display_currency, :string, required: true)

  def trips_grid(assigns) do
    ~H"""
    <div
      id="trips-grid"
      class="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-8"
      phx-update="stream"
    >
      <.trip_card
        :for={{id, trip} <- @trips}
        trip={trip}
        id={id}
        display_currency={@display_currency}
      />
    </div>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:budget, Money, required: true)
  attr(:display_currency, :string, required: true)
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
      <.budget_display budget={@budget} display_currency={@display_currency} class="gap-1" />
      <.inline class="gap-1">
        <.icon name="hero-calendar" class={"h-4 w-4 #{@icon_class}"} />
        {@trip.duration} {ngettext("day", "days", @trip.duration)}
      </.inline>
      <.inline class="gap-1">
        <.icon name="hero-user" class={"h-4 w-4 #{@icon_class}"} />
        {@trip.people_count} {gettext("ppl")}
      </.inline>
    </.inline>
    """
  end

  attr(:id, :string, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)

  def trip_card(assigns) do
    budget = Planning.calculate_budget(assigns.trip)

    cover_url =
      if TripCover.present?(assigns.trip.cover) do
        TripCover.url({assigns.trip.cover, assigns.trip}, :card)
      else
        placeholder_image(assigns.trip.id)
      end

    assigns = assign(assigns, budget: budget, cover_url: cover_url)

    ~H"""
    <.card id={@id}>
      <div class="shrink-0">
        <.link navigate={trip_url(@trip.slug)}>
          <img
            src={@cover_url}
            class="w-32 h-32 object-cover object-center rounded-l-lg"
          />
        </.link>
      </div>
      <div class="p-4 max-w-[calc(100%-theme(width.32))] flex flex-col justify-between">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <.link navigate={trip_url(@trip.slug)}>
            {@trip.name}
            <span class="font-light text-zinc-600 dark:text-zinc-400">
              {Formatter.year_with_month(@trip.start_date)}
            </span>
          </.link>
        </p>
        <.secondary tag="div" italic={false} class="font-light">
          <.shorts
            trip={@trip}
            budget={@budget}
            display_currency={@display_currency}
            class="text-sm sm:text-base"
            icon_class="hidden sm:block"
          />
        </.secondary>
        <.status_row trip={@trip} flags_limit={1} />
      </div>
    </.card>
    """
  end

  attr(:trip, Trip, required: true)
  attr(:class, :string, default: nil)
  attr(:flags_limit, :integer, default: 100)

  def status_row(assigns) do
    ~H"""
    <.inline class={
      CoreComponents.build_class([
        "gap-3",
        @class
      ])
    }>
      <.status_badge status={@trip.status} />
      <.flag
        :for={country <- Enum.take(@trip.countries, @flags_limit)}
        size={20}
        country={country.iso}
      />
      <.avatar
        size="xs"
        src={@trip.author.avatar_url}
        name={@trip.author.name}
        random_color
        class="w-6! h-6!"
      />
    </.inline>
    """
  end

  attr(:status, :string, required: true)
  attr(:class, :string, default: nil)

  def status_badge(assigns) do
    ~H"""
    <span class={
      CoreComponents.build_class([
        "flex items-center h-6 px-3 text-xs font-semibold rounded-full #{status_colors(assigns)}",
        @class
      ])
    }>
      {Gettext.gettext(HamsterTravelWeb.Gettext, @status)}
    </span>
    """
  end

  defp status_colors(%{status: status}) do
    colors = %{
      Trip.finished() => "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-100",
      Trip.draft() => "text-pink-500 bg-pink-100 dark:bg-pink-800 dark:text-pink-100",
      Trip.planned() => "text-yellow-500 bg-yellow-200 dark:bg-yellow-800 dark:text-yellow-200"
    }

    Map.get(colors, status)
  end
end
