defmodule HamsterTravel.Planning.Activities do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Planning.Activity
  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

  def get_activity!(id) do
    Repo.get!(Activity, id)
    |> preloading()
  end

  def list_activities(%Trip{id: trip_id}) do
    list_activities(trip_id)
  end

  def list_activities(trip_id) do
    Repo.all(
      from a in Activity, where: a.trip_id == ^trip_id, order_by: [asc: a.day_index, asc: a.rank]
    )
    |> preloading()
  end

  def create_activity(trip, attrs \\ %{}) do
    # Ensure the expense has trip_id if it exists in attrs
    attrs =
      case Map.get(attrs, "expense") do
        nil -> attrs
        expense_attrs -> Map.put(attrs, "expense", Map.put(expense_attrs, "trip_id", trip.id))
      end

    %Activity{trip_id: trip.id}
    |> Activity.changeset(attrs)
    |> Repo.insert()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:activity, :created], trip.id)
  end

  def update_activity(%Activity{} = activity, attrs) do
    activity
    |> Activity.changeset(attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:activity, :updated], activity.trip_id)
  end

  def new_activity(trip, day_index, attrs \\ %{}) do
    %Activity{
      trip_id: trip.id,
      day_index: day_index,
      priority: 2,
      expense: %Expense{price: Money.new(trip.currency, 0)}
    }
    |> Activity.changeset(attrs)
  end

  def change_activity(%Activity{} = activity, attrs \\ %{}) do
    Activity.changeset(activity, attrs)
  end

  def delete_activity(%Activity{} = activity) do
    Repo.delete(activity)
    |> PubSub.broadcast([:activity, :deleted], activity.trip_id)
  end

  def move_activity_to_day(activity, new_day_index, trip, user, position \\ :last)

  def move_activity_to_day(nil, _new_day_index, _trip, _user, _position),
    do: {:error, "Activity not found"}

  def move_activity_to_day(activity, new_day_index, trip, user, position) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_activity_belongs_to_trip(activity, trip),
         :ok <- Common.validate_day_index_in_trip_duration(new_day_index, trip.duration) do
      update_activity_position(activity, %{day_index: new_day_index, position: position})
    end
  end

  def reorder_activity(nil, _position, _trip, _user), do: {:error, "Activity not found"}

  def reorder_activity(activity, position, trip, user) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_activity_belongs_to_trip(activity, trip) do
      update_activity_position(activity, %{position: position})
    end
  end

  def activities_for_day(day_index, activities) do
    Common.singular_items_for_day(day_index, activities)
    |> Enum.sort_by(& &1.rank)
  end

  def preloading_query do
    [:expense]
  end

  defp validate_activity_belongs_to_trip(activity, %Trip{activities: activities}) do
    if Enum.any?(activities, &(&1.id == activity.id)) do
      :ok
    else
      {:error, "Activity not found"}
    end
  end

  defp update_activity_position(activity, attrs) do
    activity
    |> Activity.changeset(attrs)
    |> Repo.update(stale_error_field: :id)
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:activity, :updated], activity.trip_id)
  end

  defp preloading(query) do
    query
    |> Repo.preload(preloading_query())
  end
end
