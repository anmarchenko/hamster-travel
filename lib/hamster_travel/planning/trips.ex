defmodule HamsterTravel.Planning.Trips do
  @moduledoc false

  import Ecto.Query, warn: false

  use Gettext, backend: HamsterTravelWeb.Gettext

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

  alias HamsterTravel.Planning.TripCover

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

  def new_trip(%Trip{} = trip) do
    name = "#{trip.name} (#{gettext("Copy")})"

    Trip.changeset(
      struct(Trip, %{
        name: name,
        status: trip.status,
        dates_unknown: trip.dates_unknown,
        start_date: trip.start_date,
        end_date: trip.end_date,
        duration: trip.duration,
        currency: trip.currency,
        people_count: trip.people_count,
        private: trip.private
      }),
      %{}
    )
  end

  def new_trip(params) when is_map(params) do
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

  def create_trip(attrs, user, %Trip{} = source_trip) do
    source_trip = single_trip_preloading(source_trip)

    Multi.new()
    |> Multi.insert(:trip, Trip.changeset(%Trip{author_id: user.id}, attrs))
    |> Multi.run(:copy_associations, fn repo, %{trip: trip} ->
      case copy_trip_associations(repo, trip, source_trip) do
        :ok -> {:ok, trip}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{trip: trip}} ->
        {:ok, trip}

      {:error, :trip, changeset, _} ->
        {:error, changeset}

      {:error, :copy_associations, changeset, _} ->
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

  def update_trip_cover(%Trip{} = trip, %Plug.Upload{} = upload) do
    with {:ok, file_name} <- TripCover.store({upload, trip}) do
      cover = %{
        file_name: file_name,
        updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      }

      Repo.update(Ecto.Changeset.change(trip, cover: cover))
    end
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

  defp copy_trip_associations(repo, %Trip{} = trip, %Trip{} = source_trip) do
    with :ok <- copy_destinations(repo, trip, source_trip.destinations),
         :ok <- copy_accommodations(repo, trip, source_trip.accommodations),
         :ok <- copy_transfers(repo, trip, source_trip.transfers),
         :ok <- copy_activities(repo, trip, source_trip.activities),
         :ok <- copy_day_expenses(repo, trip, source_trip.day_expenses),
         :ok <- copy_notes(repo, trip, source_trip.notes),
         :ok <- copy_food_expense(repo, trip, source_trip.food_expense),
         :ok <- copy_standalone_expenses(repo, trip, source_trip.expenses) do
      :ok
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp copy_destinations(repo, %Trip{} = trip, destinations) do
    destinations
    |> Enum.reduce_while(:ok, fn destination, :ok ->
      %Destination{
        trip_id: trip.id,
        city_id: destination.city_id,
        start_day: destination.start_day,
        end_day: destination.end_day
      }
      |> repo.insert()
      |> case do
        {:ok, _} -> {:cont, :ok}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_accommodations(repo, %Trip{} = trip, accommodations) do
    accommodations
    |> Enum.reduce_while(:ok, fn accommodation, :ok ->
      %Accommodation{
        trip_id: trip.id,
        name: accommodation.name,
        link: accommodation.link,
        address: accommodation.address,
        note: accommodation.note,
        start_day: accommodation.start_day,
        end_day: accommodation.end_day
      }
      |> repo.insert()
      |> case do
        {:ok, record} ->
          case copy_expense_for(repo, trip, accommodation.expense, :accommodation_id, record.id) do
            :ok -> {:cont, :ok}
            {:error, changeset} -> {:halt, {:error, changeset}}
          end

        {:error, changeset} ->
          {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_transfers(repo, %Trip{} = trip, transfers) do
    transfers
    |> Enum.reduce_while(:ok, fn transfer, :ok ->
      %Transfer{
        trip_id: trip.id,
        day_index: transfer.day_index,
        transport_mode: transfer.transport_mode,
        departure_time: transfer.departure_time,
        arrival_time: transfer.arrival_time,
        note: transfer.note,
        vessel_number: transfer.vessel_number,
        carrier: transfer.carrier,
        departure_station: transfer.departure_station,
        arrival_station: transfer.arrival_station,
        departure_city_id: transfer.departure_city_id,
        arrival_city_id: transfer.arrival_city_id
      }
      |> repo.insert()
      |> case do
        {:ok, record} ->
          case copy_expense_for(repo, trip, transfer.expense, :transfer_id, record.id) do
            :ok -> {:cont, :ok}
            {:error, changeset} -> {:halt, {:error, changeset}}
          end

        {:error, changeset} ->
          {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_activities(repo, %Trip{} = trip, activities) do
    activities
    |> Enum.reduce_while(:ok, fn activity, :ok ->
      %Activity{
        trip_id: trip.id,
        name: activity.name,
        day_index: activity.day_index,
        priority: activity.priority,
        link: activity.link,
        address: activity.address,
        description: activity.description,
        rank: activity.rank
      }
      |> repo.insert()
      |> case do
        {:ok, record} ->
          case copy_expense_for(repo, trip, activity.expense, :activity_id, record.id) do
            :ok -> {:cont, :ok}
            {:error, changeset} -> {:halt, {:error, changeset}}
          end

        {:error, changeset} ->
          {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_day_expenses(repo, %Trip{} = trip, day_expenses) do
    day_expenses
    |> Enum.reduce_while(:ok, fn day_expense, :ok ->
      %DayExpense{
        trip_id: trip.id,
        name: day_expense.name,
        day_index: day_expense.day_index,
        rank: day_expense.rank
      }
      |> repo.insert()
      |> case do
        {:ok, record} ->
          case copy_expense_for(repo, trip, day_expense.expense, :day_expense_id, record.id) do
            :ok -> {:cont, :ok}
            {:error, changeset} -> {:halt, {:error, changeset}}
          end

        {:error, changeset} ->
          {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_notes(repo, %Trip{} = trip, notes) do
    notes
    |> Enum.reduce_while(:ok, fn note, :ok ->
      %Note{
        trip_id: trip.id,
        title: note.title,
        text: note.text,
        day_index: note.day_index,
        rank: note.rank
      }
      |> repo.insert()
      |> case do
        {:ok, _} -> {:cont, :ok}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_food_expense(_repo, _trip, nil), do: :ok

  defp copy_food_expense(repo, %Trip{} = trip, %FoodExpense{} = food_expense) do
    %FoodExpense{
      trip_id: trip.id,
      price_per_day: food_expense.price_per_day,
      days_count: food_expense.days_count,
      people_count: food_expense.people_count
    }
    |> repo.insert()
    |> case do
      {:ok, record} ->
        copy_expense_for(repo, trip, food_expense.expense, :food_expense_id, record.id)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp copy_standalone_expenses(repo, %Trip{} = trip, expenses) do
    expenses
    |> Enum.filter(&standalone_expense?/1)
    |> Enum.reduce_while(:ok, fn expense, :ok ->
      %Expense{
        trip_id: trip.id,
        name: expense.name,
        price: expense.price
      }
      |> repo.insert()
      |> case do
        {:ok, _} -> {:cont, :ok}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp copy_expense_for(_repo, _trip, nil, _foreign_key, _parent_id), do: :ok

  defp copy_expense_for(repo, %Trip{} = trip, %Expense{} = expense, foreign_key, parent_id) do
    %Expense{
      trip_id: trip.id,
      name: expense.name,
      price: expense.price
    }
    |> Map.put(foreign_key, parent_id)
    |> repo.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp standalone_expense?(%Expense{} = expense) do
    is_nil(expense.accommodation_id) and
      is_nil(expense.transfer_id) and
      is_nil(expense.activity_id) and
      is_nil(expense.day_expense_id) and
      is_nil(expense.food_expense_id)
  end
end
