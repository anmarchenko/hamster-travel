defmodule HamsterTravelWeb.Planning.TabActivity do
  @moduledoc """
  Activities tab
  """
  use HamsterTravelWeb, :live_component

  import PhxComponentHelpers

  import HamsterTravelWeb.Icons.Budget
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Planning.{DayLabel, PlacesList}
  import HamsterTravelWeb.Secondary

  alias HamsterTravelWeb.Planning.{Activity, Expense, Note, Place}

  def update(assigns, socket) do
    plan = assigns[:plan]
    budget = HamsterTravel.fetch_budget(plan, :activities)

    assigns =
      assigns
      |> set_attributes(
        [
          budget: budget,
          places: plan.places,
          activities: plan.activities,
          notes: plan.notes,
          expenses: plan.expenses
        ],
        required: [:plan]
      )

    {:ok, assign(socket, assigns)}
  end

  def activities(%{activities: activities, day_index: day_index} = assigns) do
    case HamsterTravel.filter_activities_by_day(activities, day_index) do
      [] ->
        ~H"""
        <.secondary class="sm:hidden">
          <%= gettext("No activities planned for this day") %>
        </.secondary>
        """

      activities_for_day ->
        ~H"""
        <%= for {activity, index} <-  Enum.with_index(activities_for_day)  do %>
          <.live_component
            module={Activity}
            id={"activities-#{activity.id}-day-#{day_index}"}
            activity={activity}
            index={index}
            day_index={day_index}
          />
        <% end %>
        """
    end
  end

  def places(%{places: places, day_index: day_index} = assigns) do
    places_for_day = HamsterTravel.filter_places_by_day(places, day_index)

    ~H"""
    <.places_list places={places_for_day} day_index={day_index} />
    """
  end

  def expenses(%{expenses: expenses, day_index: day_index} = assigns) do
    expenses_for_day = HamsterTravel.filter_expenses_by_day(expenses, day_index)

    ~H"""
    <%= for expense <-  expenses_for_day  do %>
      <.live_component
        module={Expense}
        id={"expenses-#{expense.id}-day-#{day_index}"}
        expense={expense}
        day_index={day_index}
      />
    <% end %>
    """
  end

  def note(%{notes: notes, day_index: day_index} = assigns) do
    case HamsterTravel.find_note_by_day(notes, day_index) do
      nil ->
        ~H"""

        """

      note ->
        ~H"""
        <.live_component
          module={Note}
          id={"notes-#{note.id}-day-#{day_index}"}
          note={note}
          day_index={day_index}
        />
        """
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row gap-x-4 mt-4 sm:mt-8 text-xl">
        <.inline>
          <.budget />
          <%= Formatter.format_money(@budget, @plan.currency) %>
        </.inline>
      </div>

      <div class="flex flex-col gap-y-8 mt-8">
        <%= for i <- 0..@plan.duration-1 do %>
          <div class="flex flex-col gap-y-2">
            <div class="text-xl font-semibold">
              <.day_label index={i} start_date={@plan.start_date} />
            </div>
            <div class="flex flex-row gap-x-4">
              <.places places={@places} day_index={i} />
            </div>
            <.note notes={@notes} day_index={i} />
            <.expenses expenses={@expenses} day_index={i} />
            <div class="flex flex-col mt-4">
              <.activities activities={@activities} day_index={i} />
            </div>
            <hr />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
