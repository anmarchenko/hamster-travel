defmodule HamsterTravelWeb.Planning.PlanningComponents do
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Icons.{Airplane, Budget}

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
  alias HamsterTravelWeb.CoreComponents

  alias HamsterTravelWeb.Planning.{
    Accommodation,
    AccommodationNew,
    Destination,
    DestinationNew,
    Transfer
  }

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

  attr(:trip, Trip, required: true)
  attr(:destinations, :list, required: true)
  attr(:day_index, :integer, required: true)

  def destinations_list(assigns) do
    ~H"""
    <.live_component
      :for={destination <- @destinations}
      module={Destination}
      id={"destination-#{destination.id}-day-#{@day_index}"}
      trip={@trip}
      destination={destination}
      day_index={@day_index}
    />
    """
  end

  attr(:budget, Money, required: true)
  attr(:class, :string, default: nil)

  def budget_display(assigns) do
    ~H"""
    <div class={
      CoreComponents.build_class([
        "flex flex-row gap-x-4 mt-4 sm:mt-8 text-xl",
        @class
      ])
    }>
      <.inline>
        <.budget />
        {Formatter.format_money(@budget.amount, @budget.currency)}
      </.inline>
    </div>
    """
  end

  attr(:trips, :list, required: true)

  def trips_grid(assigns) do
    ~H"""
    <div
      id="trips-grid"
      class="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-8"
      phx-update="stream"
    >
      <.trip_card :for={{id, trip} <- @trips} trip={trip} id={id} />
    </div>
    """
  end

  attr(:trip, Trip, required: true)
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
              {Formatter.year_with_month(@trip.start_date)}
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
        :for={country <- @trip.countries |> Enum.take(@flags_limit)}
        size={20}
        country={country.iso}
      />
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

  attr(:trip, Trip, required: true)
  attr(:budget, Money, required: true)
  attr(:destinations, :list, required: true)
  attr(:destinations_outside, :list, required: true)
  attr(:transfers, :list, required: true)
  attr(:accommodations, :list, required: true)
  attr(:accommodations_outside, :list, required: true)

  def tab_itinerary(assigns) do
    ~H"""
    <div>
      <.budget_display budget={@budget} />

      <.toggle
        :if={Enum.any?(@destinations_outside) || Enum.any?(@accommodations_outside)}
        label={gettext("Some items are scheduled outside of the trip duration")}
        class="mt-4"
      >
        <.destinations_list trip={@trip} destinations={@destinations_outside} day_index={0} />
        <.accommodations_list trip={@trip} accommodations={@accommodations_outside} day_index={0} />
      </.toggle>

      <table class="sm:mt-8 sm:table-auto sm:border-collapse sm:border sm:border-slate-500 sm:w-full">
        <thead>
          <tr class="hidden sm:table-row">
            <th class="border border-slate-600 px-2 py-4 text-left w-1/12">{gettext("Day")}</th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/6">
              {gettext("Places")}
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">
              {gettext("Transfers")}
            </th>
            <th class="border border-slate-600 px-2 py-4 text-left w-1/3">{gettext("Hotel")}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={i <- 0..(@trip.duration - 1)}
            class="flex flex-col gap-y-6 mt-10 sm:table-row sm:gap-y-0 sm:mt-0"
          >
            <td class="text-xl font-bold sm:font-normal sm:text-base sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <.day_label day_index={i} start_date={@trip.start_date} />
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col">
                <.destinations_list
                  trip={@trip}
                  destinations={Planning.destinations_for_day(i, @destinations)}
                  day_index={i}
                />
                <.live_component
                  module={DestinationNew}
                  id={"destination-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                  class="mt-2"
                />
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-8">
                <.transfers
                  transfers={HamsterTravel.filter_transfers_by_day(@transfers, i)}
                  day_index={i}
                />
              </div>
            </td>
            <td class="sm:border sm:border-slate-600 sm:px-2 sm:py-4 align-top">
              <div class="flex flex-col gap-y-8">
                <.accommodations_list
                  trip={@trip}
                  accommodations={Planning.accommodations_for_day(i, @accommodations)}
                  day_index={i}
                />
                <.live_component
                  module={AccommodationNew}
                  id={"accommodation-new-#{i}"}
                  trip={@trip}
                  day_index={i}
                  class="mt-2"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:transfers, :list, required: true)
  attr(:day_index, :integer, required: true)

  def transfers(%{transfers: []} = assigns) do
    ~H"""
    <.secondary class="sm:hidden">
      {gettext("No transfers planned for this day")}
    </.secondary>
    """
  end

  def transfers(assigns) do
    ~H"""
    <.live_component
      :for={transfer <- @transfers}
      module={Transfer}
      id={"transfers-#{transfer.id}-day-#{@day_index}"}
      transfer={transfer}
    />
    """
  end

  attr(:trip, Trip, required: true)
  attr(:accommodations, :list, required: true)
  attr(:day_index, :integer, required: true)

  def accommodations_list(assigns) do
    ~H"""
    <.live_component
      :for={accommodation <- @accommodations}
      module={Accommodation}
      id={"accommodation-#{accommodation.id}-day-#{@day_index}"}
      trip={@trip}
      accommodation={accommodation}
      day_index={@day_index}
    />
    """
  end

  attr(:trip, Trip, required: true)
  attr(:budget, Money, required: true)
  attr(:destinations, :list, required: true)
  attr(:destinations_outside, :list, required: true)
  attr(:activities, :list, required: true)
  attr(:expenses, :list, required: true)
  attr(:notes, :list, required: true)

  def tab_activity(assigns) do
    ~H"""
    <div id={"activities-#{@trip.id}"}>
      <.budget_display budget={@budget} />

      <.toggle
        :if={Enum.any?(@destinations_outside)}
        label={gettext("Some items are scheduled outside of the trip duration")}
        class="mt-4"
      >
        <.destinations_list trip={@trip} destinations={@destinations_outside} day_index={0} />
      </.toggle>

      <div class="flex flex-col gap-y-8 mt-8">
        <div :for={i <- 0..(@trip.duration - 1)} class="flex flex-col gap-y-2">
          <div class="text-xl font-semibold">
            <.day_label day_index={i} start_date={@trip.start_date} />
          </div>
          <div class="flex flex-row gap-x-4">
            <.destinations_list
              trip={@trip}
              destinations={Planning.destinations_for_day(i, @destinations)}
              day_index={i}
            />
          </div>
          <div class="inline-block">
            <.live_component
              module={DestinationNew}
              id={"destination-new-#{i}"}
              trip={@trip}
              day_index={i}
              class="inline-block"
            />
          </div>

          <.note note={HamsterTravel.find_note_by_day(@notes, i)} day_index={i} />
          <.expenses expenses={HamsterTravel.filter_expenses_by_day(@expenses, i)} day_index={i} />
          <div class="flex flex-col mt-4">
            <.activities
              activities={HamsterTravel.filter_activities_by_day(@activities, i)}
              day_index={i}
            />
          </div>
          <hr />
        </div>
      </div>
    </div>
    """
  end

  attr(:activities, :list, required: true)
  attr(:day_index, :integer, required: true)

  def activities(%{activities: []} = assigns) do
    ~H"""
    <.secondary class="sm:hidden">
      {gettext("No activities planned for this day")}
    </.secondary>
    """
  end

  def activities(assigns) do
    ~H"""
    <.live_component
      :for={{activity, index} <- Enum.with_index(@activities)}
      module={Activity}
      id={"activities-#{activity.id}-day-#{@day_index}"}
      activity={activity}
      index={index}
    />
    """
  end

  attr(:expenses, :list, required: true)
  attr(:day_index, :integer, required: true)

  def expenses(assigns) do
    ~H"""
    <.live_component
      :for={expense <- @expenses}
      module={Expense}
      id={"expenses-#{expense.id}-day-#{@day_index}"}
      expense={expense}
    />
    """
  end

  attr(:note, :map, required: true)
  attr(:day_index, :integer, required: true)

  def note(%{note: nil} = assigns) do
    ~H"""
    """
  end

  def note(assigns) do
    ~H"""
    <.live_component module={Note} id={"notes-#{@note.id}-day-#{@day_index}"} note={@note} />
    """
  end
end
