defmodule HamsterTravel.Planning.Accommodations do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Planning.Accommodation
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Repo

  def get_accommodation!(id) do
    Repo.get!(Accommodation, id)
    |> preloading()
  end

  def list_accommodations(%Trip{id: trip_id}) do
    list_accommodations(trip_id)
  end

  def list_accommodations(trip_id) do
    Repo.all(from a in Accommodation, where: a.trip_id == ^trip_id, order_by: [asc: a.start_day])
    |> preloading()
  end

  def create_accommodation(trip, attrs \\ %{}) do
    # Ensure the expense has trip_id if it exists in attrs
    attrs =
      case Map.get(attrs, "expense") do
        nil -> attrs
        expense_attrs -> Map.put(attrs, "expense", Map.put(expense_attrs, "trip_id", trip.id))
      end

    %Accommodation{trip_id: trip.id}
    |> Accommodation.changeset(attrs)
    |> Repo.insert()
    |> Common.preload_after_db_call(&Repo.preload(&1, [:expense]))
    |> PubSub.broadcast([:accommodation, :created], trip.id)
  end

  def update_accommodation(%Accommodation{} = accommodation, attrs) do
    accommodation
    |> Accommodation.changeset(attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&Repo.preload(&1, [:expense]))
    |> PubSub.broadcast([:accommodation, :updated], accommodation.trip_id)
  end

  def new_accommodation(trip, day_index, attrs \\ %{}) do
    default_days =
      if Ecto.assoc_loaded?(trip.accommodations) && Enum.empty?(trip.accommodations) do
        %{start_day: 0, end_day: trip.duration - 1}
      else
        %{start_day: day_index, end_day: day_index}
      end

    %Accommodation{
      start_day: default_days.start_day,
      end_day: default_days.end_day,
      trip_id: trip.id,
      expense: %Expense{price: Money.new(trip.currency, 0)}
    }
    |> Accommodation.changeset(attrs)
  end

  def change_accommodation(%Accommodation{} = accommodation, attrs \\ %{}) do
    Accommodation.changeset(accommodation, attrs)
  end

  def delete_accommodation(%Accommodation{} = accommodation) do
    Repo.delete(accommodation)
    |> PubSub.broadcast([:accommodation, :deleted], accommodation.trip_id)
  end

  def maybe_adjust_for_duration(%Trip{} = updated_trip, %Trip{} = original_trip) do
    if updated_trip.duration != original_trip.duration do
      adjust_for_duration(updated_trip)
    end

    updated_trip
  end

  def adjust_for_duration(%Trip{id: trip_id, duration: new_duration}) do
    from(a in Accommodation,
      where: a.trip_id == ^trip_id and a.start_day < ^new_duration and a.end_day >= ^new_duration
    )
    |> Repo.update_all(set: [end_day: new_duration - 1])
  end

  defp preloading(query) do
    query
    |> Repo.preload([:expense])
  end
end
