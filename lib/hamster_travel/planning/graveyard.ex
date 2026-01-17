defmodule HamsterTravel.Planning.Graveyard do
  @moduledoc false

  alias HamsterTravel.Repo

  alias HamsterTravel.Planning.{
    Accommodation,
    Activity,
    DayExpense,
    Destination,
    Expense,
    FoodExpense,
    Note,
    Transfer,
    Trip,
    TripTombstone
  }

  @payload_version 1

  def create_trip_tombstone!(%Trip{} = trip) do
    %TripTombstone{}
    |> TripTombstone.changeset(%{
      original_slug: to_string(trip.slug),
      author_id: trip.author_id,
      payload: build_trip_tombstone_payload(trip),
      payload_version: @payload_version
    })
    |> insert_or_rollback()
  end

  def restore_trip_from_tombstone(%TripTombstone{} = tombstone) do
    Repo.transaction(fn ->
      trip =
        tombstone
        |> build_trip_restore_attrs()
        |> then(&Trip.changeset(%Trip{}, &1))
        |> insert_or_rollback()

      tombstone.payload
      |> restore_trip_associations(trip)

      delete_or_rollback(tombstone)
      trip
    end)
    |> case do
      {:ok, %Trip{} = trip} -> {:ok, trip}
      {:error, reason} -> {:error, reason}
    end
  end

  def restore_trip_from_tombstone(tombstone_id) when is_binary(tombstone_id) do
    tombstone_id
    |> get_trip_tombstone!()
    |> restore_trip_from_tombstone()
  end

  def get_trip_tombstone!(id) do
    Repo.get!(TripTombstone, id)
  end

  defp build_trip_tombstone_payload(%Trip{} = trip) do
    %{
      "version" => @payload_version,
      "trip" => trip_payload(trip),
      "destinations" => Enum.map(trip.destinations, &destination_payload/1),
      "accommodations" => Enum.map(trip.accommodations, &accommodation_payload/1),
      "transfers" => Enum.map(trip.transfers, &transfer_payload/1),
      "activities" => Enum.map(trip.activities, &activity_payload/1),
      "day_expenses" => Enum.map(trip.day_expenses, &day_expense_payload/1),
      "notes" => Enum.map(trip.notes, &note_payload/1),
      "food_expense" => food_expense_payload(trip.food_expense),
      "expenses" => standalone_expenses_payload(trip.expenses)
    }
  end

  defp trip_payload(%Trip{} = trip) do
    %{
      "name" => trip.name,
      "slug" => to_string(trip.slug),
      "status" => trip.status,
      "dates_unknown" => trip.dates_unknown,
      "start_date" => date_to_iso(trip.start_date),
      "end_date" => date_to_iso(trip.end_date),
      "duration" => trip.duration,
      "currency" => trip.currency,
      "people_count" => trip.people_count,
      "private" => trip.private,
      "author_id" => trip.author_id,
      "inserted_at" => datetime_to_iso(trip.inserted_at),
      "updated_at" => datetime_to_iso(trip.updated_at)
    }
  end

  defp destination_payload(%Destination{} = destination) do
    %{
      "city_id" => destination.city_id,
      "start_day" => destination.start_day,
      "end_day" => destination.end_day,
      "inserted_at" => datetime_to_iso(destination.inserted_at),
      "updated_at" => datetime_to_iso(destination.updated_at)
    }
  end

  defp accommodation_payload(%Accommodation{} = accommodation) do
    %{
      "name" => accommodation.name,
      "link" => accommodation.link,
      "address" => accommodation.address,
      "note" => accommodation.note,
      "start_day" => accommodation.start_day,
      "end_day" => accommodation.end_day,
      "expense" => expense_payload(accommodation.expense),
      "inserted_at" => datetime_to_iso(accommodation.inserted_at),
      "updated_at" => datetime_to_iso(accommodation.updated_at)
    }
  end

  defp transfer_payload(%Transfer{} = transfer) do
    %{
      "day_index" => transfer.day_index,
      "transport_mode" => transfer.transport_mode,
      "departure_time" => datetime_to_iso(transfer.departure_time),
      "arrival_time" => datetime_to_iso(transfer.arrival_time),
      "note" => transfer.note,
      "vessel_number" => transfer.vessel_number,
      "carrier" => transfer.carrier,
      "departure_station" => transfer.departure_station,
      "arrival_station" => transfer.arrival_station,
      "departure_city_id" => transfer.departure_city_id,
      "arrival_city_id" => transfer.arrival_city_id,
      "expense" => expense_payload(transfer.expense),
      "inserted_at" => datetime_to_iso(transfer.inserted_at),
      "updated_at" => datetime_to_iso(transfer.updated_at)
    }
  end

  defp activity_payload(%Activity{} = activity) do
    %{
      "name" => activity.name,
      "day_index" => activity.day_index,
      "priority" => activity.priority,
      "link" => activity.link,
      "address" => activity.address,
      "description" => activity.description,
      "rank" => activity.rank,
      "expense" => expense_payload(activity.expense),
      "inserted_at" => datetime_to_iso(activity.inserted_at),
      "updated_at" => datetime_to_iso(activity.updated_at)
    }
  end

  defp day_expense_payload(%DayExpense{} = day_expense) do
    %{
      "name" => day_expense.name,
      "day_index" => day_expense.day_index,
      "rank" => day_expense.rank,
      "expense" => expense_payload(day_expense.expense),
      "inserted_at" => datetime_to_iso(day_expense.inserted_at),
      "updated_at" => datetime_to_iso(day_expense.updated_at)
    }
  end

  defp note_payload(%Note{} = note) do
    %{
      "title" => note.title,
      "text" => note.text,
      "day_index" => note.day_index,
      "rank" => note.rank,
      "inserted_at" => datetime_to_iso(note.inserted_at),
      "updated_at" => datetime_to_iso(note.updated_at)
    }
  end

  defp food_expense_payload(%FoodExpense{} = food_expense) do
    %{
      "price_per_day" => money_to_payload(food_expense.price_per_day),
      "days_count" => food_expense.days_count,
      "people_count" => food_expense.people_count,
      "expense" => expense_payload(food_expense.expense),
      "inserted_at" => datetime_to_iso(food_expense.inserted_at),
      "updated_at" => datetime_to_iso(food_expense.updated_at)
    }
  end

  defp food_expense_payload(_), do: nil

  defp expense_payload(%Expense{} = expense) do
    %{
      "name" => expense.name,
      "price" => money_to_payload(expense.price),
      "inserted_at" => datetime_to_iso(expense.inserted_at),
      "updated_at" => datetime_to_iso(expense.updated_at)
    }
  end

  defp expense_payload(_), do: nil

  defp standalone_expenses_payload(expenses) do
    expenses
    |> Enum.filter(&standalone_expense?/1)
    |> Enum.map(&expense_payload/1)
  end

  defp standalone_expense?(%Expense{} = expense) do
    is_nil(expense.accommodation_id) and
      is_nil(expense.transfer_id) and
      is_nil(expense.activity_id) and
      is_nil(expense.day_expense_id) and
      is_nil(expense.food_expense_id)
  end

  defp build_trip_restore_attrs(%TripTombstone{} = tombstone) do
    trip_payload = Map.get(tombstone.payload, "trip", %{})
    dates_unknown = Map.get(trip_payload, "dates_unknown", false)

    %{
      name: Map.get(trip_payload, "name"),
      status: Map.get(trip_payload, "status"),
      dates_unknown: dates_unknown,
      start_date: (dates_unknown && nil) || parse_date(Map.get(trip_payload, "start_date")),
      end_date: (dates_unknown && nil) || parse_date(Map.get(trip_payload, "end_date")),
      duration: Map.get(trip_payload, "duration"),
      currency: Map.get(trip_payload, "currency"),
      people_count: Map.get(trip_payload, "people_count"),
      private: Map.get(trip_payload, "private"),
      author_id: tombstone.author_id || Map.get(trip_payload, "author_id")
    }
  end

  defp restore_trip_associations(payload, %Trip{} = trip) do
    restore_destinations(trip, Map.get(payload, "destinations", []))
    restore_accommodations(trip, Map.get(payload, "accommodations", []))
    restore_transfers(trip, Map.get(payload, "transfers", []))
    restore_activities(trip, Map.get(payload, "activities", []))
    restore_day_expenses(trip, Map.get(payload, "day_expenses", []))
    restore_notes(trip, Map.get(payload, "notes", []))
    restore_food_expense(trip, Map.get(payload, "food_expense"))
    restore_standalone_expenses(trip, Map.get(payload, "expenses", []))
  end

  defp restore_destinations(%Trip{} = trip, destinations) do
    Enum.each(destinations, fn destination ->
      %Destination{
        trip_id: trip.id,
        city_id: Map.get(destination, "city_id"),
        start_day: Map.get(destination, "start_day"),
        end_day: Map.get(destination, "end_day")
      }
      |> insert_or_rollback()
    end)
  end

  defp restore_accommodations(%Trip{} = trip, accommodations) do
    Enum.each(accommodations, fn accommodation ->
      record =
        %Accommodation{
          trip_id: trip.id,
          name: Map.get(accommodation, "name"),
          link: Map.get(accommodation, "link"),
          address: Map.get(accommodation, "address"),
          note: Map.get(accommodation, "note"),
          start_day: Map.get(accommodation, "start_day"),
          end_day: Map.get(accommodation, "end_day")
        }
        |> insert_or_rollback()

      restore_expense_for(trip, record, Map.get(accommodation, "expense"), :accommodation_id)
    end)
  end

  defp restore_transfers(%Trip{} = trip, transfers) do
    Enum.each(transfers, fn transfer ->
      record =
        %Transfer{
          trip_id: trip.id,
          day_index: Map.get(transfer, "day_index"),
          transport_mode: Map.get(transfer, "transport_mode"),
          departure_time: parse_datetime(Map.get(transfer, "departure_time")),
          arrival_time: parse_datetime(Map.get(transfer, "arrival_time")),
          note: Map.get(transfer, "note"),
          vessel_number: Map.get(transfer, "vessel_number"),
          carrier: Map.get(transfer, "carrier"),
          departure_station: Map.get(transfer, "departure_station"),
          arrival_station: Map.get(transfer, "arrival_station"),
          departure_city_id: Map.get(transfer, "departure_city_id"),
          arrival_city_id: Map.get(transfer, "arrival_city_id")
        }
        |> insert_or_rollback()

      restore_expense_for(trip, record, Map.get(transfer, "expense"), :transfer_id)
    end)
  end

  defp restore_activities(%Trip{} = trip, activities) do
    Enum.each(activities, fn activity ->
      record =
        %Activity{
          trip_id: trip.id,
          name: Map.get(activity, "name"),
          day_index: Map.get(activity, "day_index"),
          priority: Map.get(activity, "priority"),
          link: Map.get(activity, "link"),
          address: Map.get(activity, "address"),
          description: Map.get(activity, "description"),
          rank: Map.get(activity, "rank")
        }
        |> insert_or_rollback()

      restore_expense_for(trip, record, Map.get(activity, "expense"), :activity_id)
    end)
  end

  defp restore_day_expenses(%Trip{} = trip, day_expenses) do
    Enum.each(day_expenses, fn day_expense ->
      record =
        %DayExpense{
          trip_id: trip.id,
          name: Map.get(day_expense, "name"),
          day_index: Map.get(day_expense, "day_index"),
          rank: Map.get(day_expense, "rank")
        }
        |> insert_or_rollback()

      restore_expense_for(trip, record, Map.get(day_expense, "expense"), :day_expense_id)
    end)
  end

  defp restore_notes(%Trip{} = trip, notes) do
    Enum.each(notes, fn note ->
      %Note{
        trip_id: trip.id,
        title: Map.get(note, "title"),
        text: Map.get(note, "text"),
        day_index: Map.get(note, "day_index"),
        rank: Map.get(note, "rank")
      }
      |> insert_or_rollback()
    end)
  end

  defp restore_food_expense(%Trip{} = trip, food_expense) do
    if food_expense do
      record =
        %FoodExpense{
          trip_id: trip.id,
          price_per_day: parse_money(Map.get(food_expense, "price_per_day")),
          days_count: Map.get(food_expense, "days_count"),
          people_count: Map.get(food_expense, "people_count")
        }
        |> insert_or_rollback()

      restore_expense_for(trip, record, Map.get(food_expense, "expense"), :food_expense_id)
    end
  end

  defp restore_standalone_expenses(%Trip{} = trip, expenses) do
    Enum.each(expenses, fn expense ->
      %Expense{
        trip_id: trip.id,
        name: Map.get(expense, "name"),
        price: parse_money(Map.get(expense, "price"))
      }
      |> insert_or_rollback()
    end)
  end

  defp restore_expense_for(%Trip{} = trip, parent, expense, foreign_key) do
    if expense do
      %Expense{
        trip_id: trip.id,
        name: Map.get(expense, "name"),
        price: parse_money(Map.get(expense, "price"))
      }
      |> Map.put(foreign_key, parent.id)
      |> insert_or_rollback()
    end
  end

  defp insert_or_rollback(changeset_or_struct) do
    case Repo.insert(changeset_or_struct) do
      {:ok, record} -> record
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp delete_or_rollback(record) do
    case Repo.delete(record) do
      {:ok, record} -> record
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp money_to_payload(%Money{} = money) do
    %{
      "amount" => money.amount,
      "currency" => to_string(money.currency)
    }
  end

  defp money_to_payload(nil), do: nil

  defp date_to_iso(%Date{} = date), do: Date.to_iso8601(date)
  defp date_to_iso(_), do: nil

  defp datetime_to_iso(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp datetime_to_iso(_), do: nil

  defp parse_money(%{"amount" => amount, "currency" => currency}) do
    Money.new(currency, amount)
  end

  defp parse_money(_), do: nil

  defp parse_date(nil), do: nil

  defp parse_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> parsed
      _ -> nil
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, parsed, _} -> parsed
      _ -> nil
    end
  end
end
