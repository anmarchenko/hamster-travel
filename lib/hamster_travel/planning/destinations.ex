defmodule HamsterTravel.Planning.Destinations do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning.Destination
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Repo

  def get_destination!(id) do
    Repo.get!(Destination, id)
    |> preloading()
  end

  def list_destinations(%Trip{id: trip_id}) do
    list_destinations(trip_id)
  end

  def list_destinations(trip_id) do
    Repo.all(from d in Destination, where: d.trip_id == ^trip_id)
    |> preloading()
  end

  def create_destination(trip, attrs \\ %{}) do
    %Destination{trip_id: trip.id}
    |> Destination.changeset(attrs)
    |> Repo.insert()
    |> Common.preload_after_db_call(&Repo.preload(&1, city: Geo.city_preloading_query()))
    |> PubSub.broadcast([:destination, :created], trip.id)
  end

  def update_destination(%Destination{} = destination, attrs) do
    destination
    |> Destination.changeset(attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&Repo.preload(&1, city: Geo.city_preloading_query()))
    |> PubSub.broadcast([:destination, :updated], destination.trip_id)
  end

  def new_destination(trip, day_index, attrs \\ %{}) do
    default_days =
      if Ecto.assoc_loaded?(trip.destinations) && Enum.empty?(trip.destinations) do
        %{start_day: 0, end_day: trip.duration - 1}
      else
        %{start_day: day_index, end_day: day_index}
      end

    %Destination{
      start_day: default_days.start_day,
      end_day: default_days.end_day,
      trip_id: trip.id,
      city: nil
    }
    |> Destination.changeset(attrs)
  end

  def change_destination(%Destination{} = destination, attrs \\ %{}) do
    Destination.changeset(destination, attrs)
  end

  def delete_destination(%Destination{} = destination) do
    Repo.delete(destination)
    |> PubSub.broadcast([:destination, :deleted], destination.trip_id)
  end

  def preloading(query) do
    query
    |> Repo.preload(preloading_query())
  end

  def maybe_adjust_for_duration(%Trip{} = updated_trip, %Trip{} = original_trip) do
    if updated_trip.duration != original_trip.duration do
      adjust_for_duration(updated_trip)
    end

    updated_trip
  end

  def adjust_for_duration(%Trip{id: trip_id, duration: new_duration}) do
    from(d in Destination,
      where: d.trip_id == ^trip_id and d.start_day < ^new_duration and d.end_day >= ^new_duration
    )
    |> Repo.update_all(set: [end_day: new_duration - 1])
  end

  def preloading_query do
    [
      city: Geo.city_preloading_query()
    ]
  end
end
