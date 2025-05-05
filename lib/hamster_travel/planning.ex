defmodule HamsterTravel.Planning do
  @moduledoc """
  The Planning context.
  """

  import Ecto.Query, warn: false

  alias HamsterTravel.Repo
  alias HamsterTravel.Planning.{Destination, Policy, Trip}

  def list_plans(user \\ nil) do
    query =
      from t in Trip,
        where: t.status in [^Trip.planned(), ^Trip.finished()],
        order_by: [
          asc: t.status,
          desc: t.start_date
        ]

    query
    |> Policy.user_plans_scope(user)
    |> Repo.all()
    |> trip_preloading()
  end

  def list_drafts(user) do
    query =
      from t in Trip,
        where: t.status == ^Trip.draft(),
        order_by: [
          asc: t.name
        ]

    query
    |> Policy.user_drafts_scope(user)
    |> Repo.all()
    |> trip_preloading()
  end

  def next_plans(user \\ nil) do
    query =
      from t in Trip,
        where: t.status == ^Trip.planned() and t.author_id == ^user.id,
        order_by: [
          asc: t.start_date
        ],
        limit: 4

    query
    |> Repo.all()
    |> trip_preloading()
  end

  def last_trips(user \\ nil) do
    query =
      from t in Trip,
        where: t.status == ^Trip.finished() and t.author_id == ^user.id,
        order_by: [
          desc: t.start_date
        ],
        limit: 6

    query
    |> Repo.all()
    |> trip_preloading()
  end

  def get_trip(id) do
    Trip
    |> Repo.get(id)
    |> trip_preloading()
  end

  def get_trip!(id) do
    Trip
    |> Repo.get!(id)
    |> trip_preloading()
  end

  # when there is no current user then we show only public trips
  def fetch_trip!(slug, nil) do
    query =
      from t in Trip,
        where: t.slug == ^slug and t.private == false

    query
    |> Repo.one!()
    |> trip_preloading()
  end

  # when current user is present then we show public trips and user's private trips
  def fetch_trip!(slug, user) do
    query =
      from t in Trip,
        where: t.slug == ^slug

    query
    |> Policy.user_trip_visibility_scope(user)
    |> Repo.one!()
    |> trip_preloading()
  end

  def trip_changeset(params) do
    Trip.changeset(%Trip{}, params)
  end

  def new_trip(params \\ %{}) do
    params =
      Map.merge(
        %{status: Trip.planned(), people_count: 2, private: false, currency: "EUR"},
        params
      )

    Trip.changeset(
      struct(Trip, params),
      %{}
    )
  end

  def create_trip(attrs \\ %{}, user) do
    %Trip{author_id: user.id}
    |> Trip.changeset(attrs)
    |> Repo.insert()
  end

  def update_trip(%Trip{} = trip, attrs) do
    trip
    |> Trip.changeset(attrs)
    |> Repo.update()
  end

  def delete_trip(%Trip{} = trip) do
    Repo.delete(trip)
  end

  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trip.changeset(trip, attrs)
  end

  def get_destination!(id) do
    Repo.get!(Destination, id)
    |> destinations_preloading()
  end

  def list_destinations(%Trip{id: trip_id}) do
    list_destinations(trip_id)
  end

  def list_destinations(trip_id) do
    Repo.all(from d in Destination, where: d.trip_id == ^trip_id)
    |> destinations_preloading()
  end

  def create_destination(trip, attrs \\ %{}) do
    %Destination{trip_id: trip.id}
    |> Destination.changeset(attrs)
    |> Repo.insert()
  end

  def update_destination(%Destination{} = destination, attrs) do
    destination
    |> Destination.changeset(attrs)
    |> Repo.update()
  end

  def new_destination(trip, attrs \\ %{}) do
    %Destination{trip_id: trip.id, city: nil}
    |> Destination.changeset(attrs)
  end

  def change_destination(%Destination{} = destination, attrs \\ %{}) do
    Destination.changeset(destination, attrs)
  end

  def delete_destination(%Destination{} = destination) do
    Repo.delete(destination)
  end

  defp trip_preloading(query) do
    query
    |> Repo.preload([:author, destinations: [:city]])
  end

  defp destinations_preloading(query) do
    query
    |> Repo.preload([:city])
  end
end
