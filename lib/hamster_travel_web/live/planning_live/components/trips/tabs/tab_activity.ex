defmodule HamsterTravelWeb.Planning.Trips.Tabs.TabActivity do
  @moduledoc """
  Activities tab
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Icons.Budget
  import HamsterTravelWeb.Planning.{DayLabel, PlacesList}

  alias HamsterTravelWeb.Planning.{Activity, Expense, Note}

  def update(assigns, socket) do
    # budget = HamsterTravel.fetch_budget(plan, :activities)
    budget = 0

    socket =
      socket
      |> assign(assigns)
      |> assign(
        budget: budget,
        places: [],
        activities: [],
        notes: [],
        expenses: []
      )

    {:ok, socket}
  end

  def activities(%{activities: []} = assigns) do
    ~H"""
    <.secondary class="sm:hidden">
      <%= gettext("No activities planned for this day") %>
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

  def note(%{note: nil} = assigns) do
    ~H"""
    """
  end

  def note(assigns) do
    ~H"""
    <.live_component module={Note} id={"notes-#{@note.id}-day-#{@day_index}"} note={@note} />
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row gap-x-4 mt-4 sm:mt-8 text-xl">
        <.inline>
          <.budget />
          <%= Formatter.format_money(@budget, @trip.currency) %>
        </.inline>
      </div>

      <div class="flex flex-col gap-y-8 mt-8">
        <div :for={i <- 0..(@trip.duration - 1)} class="flex flex-col gap-y-2">
          <div class="text-xl font-semibold">
            <.day_label day_index={i} start_date={@trip.start_date} />
          </div>
          <div class="flex flex-row gap-x-4">
            <.places_list places={HamsterTravel.filter_places_by_day(@places, i)} day_index={i} />
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
end
