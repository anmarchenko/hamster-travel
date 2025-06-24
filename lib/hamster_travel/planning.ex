defmodule HamsterTravel.Planning do
  @moduledoc """
  The Planning context.
  """

  import Ecto.Query, warn: false

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning.{Accommodation, Destination, Expense, Policy, Trip}
  alias HamsterTravel.Repo

  # PubSub functions
  @topic "planning"

  defp send_pubsub_event({:ok, result} = return_tuple, event, trip_id) do
    Phoenix.PubSub.broadcast(
      HamsterTravel.PubSub,
      @topic <> ":#{trip_id}",
      {event, %{value: result}}
    )

    return_tuple
  end

  defp send_pubsub_event({:error, _reason} = result, _, _), do: result

  # Trip functions

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
    %Trip{author_id: user.id}
    |> Trip.changeset(attrs)
    |> Repo.insert()
  end

  def update_trip(%Trip{} = trip, attrs) do
    Repo.transaction(fn ->
      case Repo.update(Trip.changeset(trip, attrs)) do
        {:ok, updated_trip} ->
          maybe_adjust_destinations(updated_trip, trip)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp maybe_adjust_destinations(updated_trip, original_trip) do
    if updated_trip.duration != original_trip.duration do
      adjust_destinations_for_duration(updated_trip)
    end

    updated_trip
  end

  defp adjust_destinations_for_duration(%Trip{id: trip_id, duration: new_duration}) do
    from(d in Destination,
      where: d.trip_id == ^trip_id and d.start_day < ^new_duration and d.end_day >= ^new_duration
    )
    |> Repo.update_all(set: [end_day: new_duration - 1])
  end

  def delete_trip(%Trip{} = trip) do
    Repo.delete(trip)
  end

  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trip.changeset(trip, attrs)
  end

  defp trip_preloading(query) do
    query
    |> Repo.preload([:author, :countries])
  end

  defp single_trip_preloading(query) do
    query
    |> Repo.preload([:author, :countries, destinations: [city: Geo.city_preloading_query()]])
  end

  # Destinations functions

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
    |> preload_after_db_call(&Repo.preload(&1, city: Geo.city_preloading_query()))
    |> send_pubsub_event([:destination, :created], trip.id)
  end

  def update_destination(%Destination{} = destination, attrs) do
    destination
    |> Destination.changeset(attrs)
    |> Repo.update()
    |> preload_after_db_call(&Repo.preload(&1, city: Geo.city_preloading_query()))
    |> send_pubsub_event([:destination, :updated], destination.trip_id)
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
    |> send_pubsub_event([:destination, :deleted], destination.trip_id)
  end

  @doc """
  Returns a list of destinations that are active on a given day index.
  A destination is considered active if its start_day is less than or equal to
  the day index and its end_day is greater than or equal to the day index.
  """
  def destinations_for_day(day_index, destinations) do
    items_for_day(day_index, destinations)
  end

  defp destinations_preloading(query) do
    query
    |> Repo.preload(city: Geo.city_preloading_query())
  end

  # Expense functions

  def get_expense!(id) do
    Repo.get!(Expense, id)
  end

  def list_expenses(%Trip{id: trip_id}) do
    list_expenses(trip_id)
  end

  def list_expenses(trip_id) do
    Repo.all(from e in Expense, where: e.trip_id == ^trip_id, order_by: [desc: e.inserted_at])
  end

  def create_expense(trip, attrs \\ %{}) do
    %Expense{trip_id: trip.id}
    |> Expense.changeset(attrs)
    |> Repo.insert()
    |> send_pubsub_event([:expense, :created], trip.id)
  end

  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
    |> send_pubsub_event([:expense, :updated], expense.trip_id)
  end

  def new_expense(trip, attrs \\ %{}) do
    %Expense{
      trip_id: trip.id
    }
    |> Expense.changeset(attrs)
  end

  def change_expense(%Expense{} = expense, attrs \\ %{}) do
    Expense.changeset(expense, attrs)
  end

  def delete_expense(%Expense{} = expense) do
    Repo.delete(expense)
    |> send_pubsub_event([:expense, :deleted], expense.trip_id)
  end

  # Accommodation functions

  def get_accommodation!(id) do
    Repo.get!(Accommodation, id)
    |> accommodations_preloading()
  end

  def list_accommodations(%Trip{id: trip_id}) do
    list_accommodations(trip_id)
  end

  def list_accommodations(trip_id) do
    Repo.all(from a in Accommodation, where: a.trip_id == ^trip_id, order_by: [asc: a.start_day])
    |> accommodations_preloading()
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
    |> preload_after_db_call(&Repo.preload(&1, [:expense]))
    |> send_pubsub_event([:accommodation, :created], trip.id)
  end

  def update_accommodation(%Accommodation{} = accommodation, attrs) do
    accommodation
    |> Accommodation.changeset(attrs)
    |> Repo.update()
    |> preload_after_db_call(&Repo.preload(&1, [:expense]))
    |> send_pubsub_event([:accommodation, :updated], accommodation.trip_id)
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
      trip_id: trip.id
    }
    |> Accommodation.changeset(attrs)
  end

  def change_accommodation(%Accommodation{} = accommodation, attrs \\ %{}) do
    Accommodation.changeset(accommodation, attrs)
  end

  def delete_accommodation(%Accommodation{} = accommodation) do
    Repo.delete(accommodation)
    |> send_pubsub_event([:accommodation, :deleted], accommodation.trip_id)
  end

  @doc """
  Returns a list of accommodations that are active on a given day index.
  An accommodation is considered active if its start_day is less than or equal to
  the day index and its end_day is greater than or equal to the day index.
  """
  def accommodations_for_day(day_index, accommodations) do
    items_for_day(day_index, accommodations)
  end

  defp accommodations_preloading(query) do
    query
    |> Repo.preload([:expense])
  end

  # utils
  defp items_for_day(day_index, items) do
    Enum.filter(items, fn item ->
      item.start_day <= day_index && item.end_day >= day_index
    end)
  end

  defp preload_after_db_call({:error, _} = res, _preload_fun), do: res

  defp preload_after_db_call({:ok, record}, preload_fun) do
    record = preload_fun.(record)
    {:ok, record}
  end
end
