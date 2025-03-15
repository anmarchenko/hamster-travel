defmodule HamsterTravelWeb.Planning.PlanningComponents do
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Icons.{Airplane, Budget}
  alias HamsterTravelWeb.Cldr

  alias HamsterTravel.Planning.Trip
  alias HamsterTravelWeb.CoreComponents

  attr(:trip, :map, required: true)
  attr(:active_tab, :string, required: true)
  attr(:class, :string, default: nil)

  def planning_tabs(assigns) do
    ~H"""
    <.tabs
      underline
      class={
        CoreComponents.build_class([
          "hidden sm:flex",
          @class
        ])
      }
    >
      <.tab
        underline
        to={trip_url(@trip.slug, :itinerary)}
        is_active={@active_tab == "itinerary"}
        link_type="live_patch"
      >
        <.inline>
          <.airplane />
          {gettext("Transfers and hotels")}
        </.inline>
      </.tab>
      <.tab
        underline
        to={trip_url(@trip.slug, :activities)}
        is_active={@active_tab == "activities"}
        link_type="live_patch"
      >
        <.inline>
          <.icon name="hero-clipboard-document-list" class="h-5 w-5" />
          {gettext("Activities")}
        </.inline>
      </.tab>
    </.tabs>
    """
  end

  attr(:places, :list, required: true)
  attr(:day_index, :integer, required: true)

  def places_list(assigns) do
    ~H"""
    <%!-- <.live_component
      :for={place <- @places}
      module={Place}
      id={"places-#{place.id}-day-#{@day_index}"}
      place={place}
      day_index={@day_index}
    /> --%>
    <%!-- <.live_component
      id={"search-city-new-place-#{@day_index}"}
      module={HamsterTravelWeb.Planning.DestinationForm}
    /> --%>
    """
  end

  attr(:trips, :list, required: true)

  def trips_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-8">
      <.trip_card :for={{id, trip} <- @trips} trip={trip} id={id} />
    </div>
    """
  end

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
        {Formatter.format_money(0, @trip.currency)}
      </.inline>
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
  attr(:trip, :map, required: true)

  def trip_card(assigns) do
    ~H"""
    <.card id={@id}>
      <div class="shrink-0">
        <.link navigate={trip_url(@trip.slug)}>
          <%!-- # @trip.cover ||  --%>
          <img
            src={placeholder_image(@trip.id)}
            class="w-32 h-32 object-cover object-center rounded-l-lg"
          />
        </.link>
      </div>
      <div class="p-4 max-w-[calc(100%_-_theme(width.32))] flex flex-col justify-between">
        <p class="text-base font-semibold whitespace-nowrap overflow-hidden text-ellipsis">
          <.link navigate={trip_url(@trip.slug)}>
            {@trip.name}
            <span class="font-light text-zinc-600 dark:text-zinc-400">
              {Cldr.year_with_month(@trip.start_date)}
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

  attr(:trip, :map, required: true)
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
      <.flag size={20} country="de" />
      <%!-- <%= for country <- Enum.take(@plan.countries, @flags_limit) do %>
        <.flag size={24} country={country} />
      <% end %> --%>
      <.avatar
        size="xs"
        src={@trip.author.avatar_url}
        name={@trip.author.name}
        random_color
        class="!w-6 !h-6"
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

  attr(:start_date, Date, default: nil)
  attr(:day_index, :integer, required: true)

  def day_label(%{start_date: nil} = assigns) do
    ~H"""
    {gettext("Day")} {@day_index + 1}
    """
  end

  def day_label(assigns) do
    ~H"""
    {Formatter.date_with_weekday(Date.add(@start_date, @day_index))}
    """
  end
end
