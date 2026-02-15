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

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:cta_label, :string, required: true)
  attr(:cta_to, :string, required: true)

  def trips_empty_state(assigns) do
    ~H"""
    <section class="relative overflow-hidden rounded-3xl border border-zinc-200/70 bg-gradient-to-b from-amber-50 to-white px-6 py-12 shadow-sm dark:border-zinc-700/60 dark:from-zinc-900 dark:to-zinc-950 sm:px-12 sm:py-16">
      <div class="pointer-events-none absolute -top-16 -right-16 h-48 w-48 rounded-full bg-violet-300/25 blur-3xl dark:bg-violet-500/20" />
      <div class="pointer-events-none absolute -bottom-20 -left-20 h-56 w-56 rounded-full bg-orange-200/35 blur-3xl dark:bg-amber-400/10" />
      <div class="relative mx-auto flex min-h-[58vh] max-w-2xl flex-col items-center justify-center text-center">
        <div class="mb-8 w-56 sm:w-64">
          <svg
            class="h-full w-full drop-shadow-xl"
            fill="none"
            viewBox="0 0 200 200"
            xmlns="http://www.w3.org/2000/svg"
          >
            <circle class="fill-white/75 dark:fill-zinc-800/75" cx="100" cy="100" r="90" />
            <rect
              class="fill-amber-700 dark:fill-amber-800"
              height="50"
              rx="8"
              width="80"
              x="60"
              y="120"
            />
            <rect class="fill-amber-900/20" height="5" width="80" x="60" y="130" />
            <path
              d="M85 120V110C85 105 115 105 115 110V120"
              fill="none"
              stroke="#78350f"
              stroke-width="4"
            />
            <ellipse class="fill-orange-200 dark:fill-orange-300" cx="100" cy="95" rx="35" ry="40" />
            <circle class="fill-orange-200 dark:fill-orange-300" cx="75" cy="65" r="10" />
            <circle class="fill-orange-200 dark:fill-orange-300" cx="125" cy="65" r="10" />
            <circle class="fill-pink-200" cx="75" cy="65" r="5" />
            <circle class="fill-pink-200" cx="125" cy="65" r="5" />
            <circle class="fill-zinc-800" cx="90" cy="85" r="4" />
            <circle class="fill-zinc-800" cx="110" cy="85" r="4" />
            <path d="M95 95Q100 100 105 95" stroke="#374151" stroke-linecap="round" stroke-width="2" />
            <ellipse class="fill-pink-300/50" cx="90" cy="100" rx="4" ry="2" />
            <ellipse class="fill-pink-300/50" cx="110" cy="100" rx="4" ry="2" />
            <rect
              class="fill-sky-100"
              height="30"
              rx="2"
              transform="rotate(12 110 80)"
              width="40"
              x="110"
              y="80"
            />
            <path d="M120 85L140 85M120 90L135 90M120 95L140 95" stroke="#93C5FD" stroke-width="2" />
            <circle class="fill-orange-200 dark:fill-orange-300" cx="115" cy="105" r="6" />
          </svg>
        </div>
        <h2 class="mb-3 text-3xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">
          {@title}
        </h2>
        <p class="mb-8 max-w-xl text-lg leading-relaxed text-zinc-600 dark:text-zinc-400">
          {@description}
        </p>
        <.link
          navigate={@cta_to}
          class="inline-flex items-center gap-2 rounded-xl bg-violet-600 px-6 py-3 font-medium text-white shadow-lg shadow-violet-500/30 transition hover:-translate-y-0.5 hover:bg-violet-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 focus-visible:ring-offset-2 focus-visible:ring-offset-amber-50 dark:focus-visible:ring-offset-zinc-900"
        >
          <.icon name="hero-plus-circle-solid" class="h-5 w-5" />
          {@cta_label}
        </.link>
      </div>
    </section>
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
