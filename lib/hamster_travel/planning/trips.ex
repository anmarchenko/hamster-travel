defmodule HamsterTravel.Planning.Trips do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias HamsterTravel.Planning.{
    Accommodations,
    Activities,
    DayExpenses,
    Destinations,
    FoodExpense,
    FoodExpenses,
    Graveyard,
    Note,
    Notes,
    Policy,
    Transfer,
    Transfers,
    Trip,
    TripTombstone
  }

  alias HamsterTravel.Planning.{
    Accommodation,
    Activity,
    DayExpense,
    Destination,
    Expense
  }

  alias HamsterTravel.Repo

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

  def get_trip(id) do
    Trip
    |> Repo.get(id)
    |> single_trip_preloading()
  end

  def get_trip!(id) do
    Trip
    |> Repo.get!(id)
    |> single_trip_preloading()
  end

  # when there is no current user then we show only public trips
  def fetch_trip!(slug, nil) do
    query =
      from t in Trip,
        where: t.slug == ^slug and t.private == false

    query
    |> Repo.one!()
    |> single_trip_preloading()
  end

  # when current user is present then we show public trips and user's private trips
  def fetch_trip!(slug, user) do
    query =
      from t in Trip,
        where: t.slug == ^slug

    query
    |> Policy.user_trip_visibility_scope(user)
    |> Repo.one!()
    |> single_trip_preloading()
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
    Multi.new()
    |> Multi.insert(:trip, Trip.changeset(%Trip{author_id: user.id}, attrs))
    |> Multi.run(:food_expense, fn repo, %{trip: trip} ->
      FoodExpenses.create_food_expense_with_repo(
        repo,
        trip,
        FoodExpenses.default_food_expense_attrs(trip)
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{trip: trip}} ->
        {:ok, trip}

      {:error, :trip, changeset, _} ->
        {:error, changeset}

      {:error, :food_expense, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_trip(%Trip{} = trip, attrs) do
    Repo.transaction(fn ->
      case Repo.update(Trip.changeset(trip, attrs)) do
        {:ok, updated_trip} ->
          updated_trip
          |> Destinations.maybe_adjust_for_duration(trip)
          |> Accommodations.maybe_adjust_for_duration(trip)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def delete_trip(%Trip{} = trip) do
    Repo.transaction(fn ->
      trip = single_trip_preloading(trip)
      Graveyard.create_trip_tombstone!(trip)

      from(e in Expense, where: e.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(d in Destination, where: d.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(a in Accommodation, where: a.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(t in Transfer, where: t.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(a in Activity, where: a.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(de in DayExpense, where: de.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(n in Note, where: n.trip_id == ^trip.id)
      |> Repo.delete_all()

      from(fe in FoodExpense, where: fe.trip_id == ^trip.id)
      |> Repo.delete_all()

      Repo.delete(trip)
    end)
    |> case do
      {:ok, {:ok, deleted_trip}} -> {:ok, deleted_trip}
      {:ok, {:error, changeset}} -> {:error, changeset}
      {:error, reason} -> {:error, reason}
    end
  end

  def restore_trip_from_tombstone(%TripTombstone{} = tombstone) do
    Graveyard.restore_trip_from_tombstone(tombstone)
  end

  def restore_trip_from_tombstone(tombstone_id) when is_binary(tombstone_id) do
    Graveyard.restore_trip_from_tombstone(tombstone_id)
  end

  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trip.changeset(trip, attrs)
  end

  defp trip_preloading(query) do
    query
    |> Repo.preload([:author, :countries, :expenses])
  end

  defp single_trip_preloading(query) do
    query
    |> Repo.preload([
      :author,
      :countries,
      :expenses,
      food_expense: :expense,
      accommodations: :expense,
      day_expenses: DayExpenses.preloading_query(),
      activities: Activities.preloading_query(),
      notes: Notes.preloading_query(),
      destinations: Destinations.preloading_query(),
      transfers: Transfers.preloading_query()
    ])
  end
end
