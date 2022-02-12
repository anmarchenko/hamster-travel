defmodule HamsterTravelWeb.Planning.Tabs.ActivitiesTab do
  @moduledoc """
  Activities tab
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravelWeb.Planning.{Activity, PlanComponents}

  def update(%{plan: plan}, socket) do
    budget = HamsterTravel.fetch_budget(plan, :activities)

    socket =
      socket
      |> assign(budget: budget)
      |> assign(plan: plan)
      |> assign(places: plan.places)
      |> assign(activities: plan.activities)

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
            <.live_component module={Activity} id={"activities-#{activity.id}-day-#{day_index}"} activity={activity} index={index} day_index={day_index} />
          <% end %>
        """
    end
  end
end
