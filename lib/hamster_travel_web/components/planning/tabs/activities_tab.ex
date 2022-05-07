defmodule HamsterTravelWeb.Planning.Tabs.ActivitiesTab do
  @moduledoc """
  Activities tab
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Icons.Budget

  alias HamsterTravelWeb.Planning.{Activity, Expense, Note, PlanComponents}

  def update(%{plan: plan}, socket) do
    budget = HamsterTravel.fetch_budget(plan, :activities)

    socket =
      socket
      |> assign(budget: budget)
      |> assign(plan: plan)
      |> assign(places: plan.places)
      |> assign(activities: plan.activities)
      |> assign(notes: plan.notes)
      |> assign(expenses: plan.expenses)

    {:ok, socket}
  end

  def activities_list(%{activities: activities, day_index: day_index} = assigns) do
    case HamsterTravel.filter_activities_by_day(activities, day_index) do
      [] ->
        ~H"""
        <UI.secondary_text>
          <%= gettext("No activities planned for this day") %>
        </UI.secondary_text>
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

  def expenses_list(%{expenses: expenses, day_index: day_index} = assigns) do
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
end
