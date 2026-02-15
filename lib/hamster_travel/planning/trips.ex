defmodule HamsterTravel.Planning.Trips do
  @moduledoc false

  import Ecto.Query, warn: false

  use Gettext, backend: HamsterTravelWeb.Gettext

  alias Ecto.Multi

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Social

  alias HamsterTravel.Planning.{
    Accommodations,
    Activities,
    Common,
    DayExpenses,
    Destinations,
    FoodExpense,
    FoodExpenses,
    Graveyard,
    Note,
    Notes,
    Policy,
    PubSub,
    Transfer,
    Transfers,
    Trip,
    TripParticipant,
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

  @default_page_size 12

  def list_plans(user \\ nil) do
    user
    |> plans_query()
    |> Repo.all()
    |> trip_preloading()
  end

  def list_plans_paginated(
        user \\ nil,
        page \\ 1,
        page_size \\ @default_page_size,
        search_query \\ nil
      ) do
    user
    |> plans_query()
    |> apply_search_query(search_query)
    |> paginate(page, page_size, &trip_preloading/1)
  end

  def list_drafts(user) do
    user
    |> drafts_query()
    |> Repo.all()
    |> trip_preloading()
  end

  def list_drafts_paginated(user, page \\ 1, page_size \\ @default_page_size, search_query \\ nil) do
    user
    |> drafts_query()
    |> apply_search_query(search_query)
    |> paginate(page, page_size, &trip_preloading/1)
  end

  defp plans_query(user) do
    query =
      from t in Trip,
        where: t.status in [^Trip.planned(), ^Trip.finished()],
        order_by: [
          asc: t.status,
          desc: t.start_date
        ]

    query
    |> Policy.user_plans_scope(user)
  end

  defp drafts_query(user) do
    query =
      from t in Trip,
        where: t.status == ^Trip.draft(),
        order_by: [
          asc: t.name
        ]

    query
    |> Policy.user_drafts_scope(user)
  end

  defp apply_search_query(query, search_query) do
    case to_prefix_tsquery(search_query) do
      nil ->
        query

      tsquery ->
        query
        |> where(
          [t],
          fragment(
            "(setweight(to_tsvector('simple', coalesce(?, '')), 'A') || setweight(to_tsvector('simple', coalesce(?, '')), 'B')) @@ to_tsquery('simple', ?)",
            t.name,
            t.search_text,
            ^tsquery
          )
        )
        |> prepend_order_by(
          [t],
          desc:
            fragment(
              "ts_rank_cd((setweight(to_tsvector('simple', coalesce(?, '')), 'A') || setweight(to_tsvector('simple', coalesce(?, '')), 'B')), to_tsquery('simple', ?))",
              t.name,
              t.search_text,
              ^tsquery
            )
        )
    end
  end

  defp to_prefix_tsquery(search_query) when is_binary(search_query) do
    search_query
    |> String.trim()
    |> String.split(~r/\s+/u, trim: true)
    |> Enum.map(&sanitize_search_token/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      tokens -> Enum.map_join(tokens, " & ", &"#{&1}:*")
    end
  end

  defp to_prefix_tsquery(_), do: nil

  defp sanitize_search_token(token) do
    String.replace(token, ~r/[^\p{L}\p{N}]/u, "")
  end

  def list_profile_finished_trips(%User{} = user) do
    from(t in Trip,
      left_join: tp in TripParticipant,
      on: tp.trip_id == t.id,
      where: t.status == ^Trip.finished() and (t.author_id == ^user.id or tp.user_id == ^user.id),
      distinct: true
    )
    |> Repo.all()
    |> Repo.preload([:countries, :cities])
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

  def move_day(%Trip{} = _trip, _from_day_index, _to_day_index, nil), do: {:error, "Unauthorized"}

  def move_day(%Trip{} = trip, from_day_index, to_day_index, %User{} = user) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- Common.validate_day_index_in_trip_duration(from_day_index, trip.duration),
         :ok <- Common.validate_day_index_in_trip_duration(to_day_index, trip.duration) do
      if from_day_index == to_day_index do
        {:ok, get_trip!(trip.id)}
      else
        trip
        |> move_day_transaction(from_day_index, to_day_index)
        |> PubSub.broadcast([:trip, :updated], trip.id)
      end
    end
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

  def add_trip_participant(%Trip{} = trip, %User{} = actor, participant_id)
      when is_binary(participant_id) do
    trip = preload_trip_participants(trip)

    with :ok <- authorize_participant_management(trip, actor),
         :ok <- validate_addable_participant(trip, participant_id),
         {:ok, _trip_participant} <- create_trip_participant(trip, participant_id) do
      {:ok, get_trip!(trip.id)}
    end
  end

  def remove_trip_participant(%Trip{} = trip, %User{} = actor, participant_id)
      when is_binary(participant_id) do
    trip = preload_trip_participants(trip)

    with :ok <- authorize_participant_removal(trip, actor, participant_id),
         {:ok, _trip_participant} <- delete_trip_participant(trip, participant_id) do
      {:ok, get_trip!(trip.id)}
    end
  end

  defp trip_preloading(query) do
    query
    |> Repo.preload([:author, :countries, :expenses, trip_participants: :user])
  end

  defp single_trip_preloading(query) do
    query
    |> Repo.preload([
      :author,
      :countries,
      :expenses,
      trip_participants: :user,
      food_expense: :expense,
      accommodations: :expense,
      day_expenses: DayExpenses.preloading_query(),
      activities: Activities.preloading_query(),
      notes: Notes.preloading_query(),
      destinations: Destinations.preloading_query(),
      transfers: Transfers.preloading_query()
    ])
  end

  defp preload_trip_participants(%Trip{} = trip) do
    Repo.preload(trip, trip_participants: :user)
  end

  defp move_day_transaction(%Trip{} = trip, from_day_index, to_day_index) do
    Repo.transaction(fn ->
      trip = get_trip!(trip.id)

      with :ok <- move_day_for_destinations(trip.destinations, from_day_index, to_day_index),
           :ok <- move_day_for_accommodations(trip.accommodations, from_day_index, to_day_index),
           :ok <- move_day_for_transfers(trip.transfers, from_day_index, to_day_index),
           :ok <- move_day_for_activities(trip.activities, from_day_index, to_day_index),
           :ok <- move_day_for_day_expenses(trip.day_expenses, from_day_index, to_day_index),
           :ok <- move_day_for_notes(trip.notes, from_day_index, to_day_index) do
        get_trip!(trip.id)
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp move_day_for_destinations(destinations, from_day_index, to_day_index) do
    move_day_for_records(destinations, &Destination.changeset/2, fn destination ->
      new_start_day = remap_day_index(destination.start_day, from_day_index, to_day_index)
      new_end_day = remap_day_index(destination.end_day, from_day_index, to_day_index)
      {new_start_day, new_end_day} = normalize_day_range(new_start_day, new_end_day)

      changed_attrs(destination, %{start_day: new_start_day, end_day: new_end_day})
    end)
  end

  defp move_day_for_accommodations(accommodations, from_day_index, to_day_index) do
    move_day_for_records(accommodations, &Accommodation.changeset/2, fn accommodation ->
      new_start_day = remap_day_index(accommodation.start_day, from_day_index, to_day_index)
      new_end_day = remap_day_index(accommodation.end_day, from_day_index, to_day_index)
      {new_start_day, new_end_day} = normalize_day_range(new_start_day, new_end_day)

      changed_attrs(accommodation, %{start_day: new_start_day, end_day: new_end_day})
    end)
  end

  defp move_day_for_transfers(transfers, from_day_index, to_day_index) do
    move_day_for_records(transfers, &Transfer.changeset/2, fn transfer ->
      new_day_index = remap_day_index(transfer.day_index, from_day_index, to_day_index)
      changed_attrs(transfer, %{day_index: new_day_index})
    end)
  end

  defp move_day_for_activities(activities, from_day_index, to_day_index) do
    move_day_for_records(activities, &Activity.changeset/2, fn activity ->
      new_day_index = remap_day_index(activity.day_index, from_day_index, to_day_index)
      changed_attrs(activity, %{day_index: new_day_index})
    end)
  end

  defp move_day_for_day_expenses(day_expenses, from_day_index, to_day_index) do
    move_day_for_records(day_expenses, &DayExpense.changeset/2, fn day_expense ->
      new_day_index = remap_day_index(day_expense.day_index, from_day_index, to_day_index)
      changed_attrs(day_expense, %{day_index: new_day_index})
    end)
  end

  defp move_day_for_notes(notes, from_day_index, to_day_index) do
    move_day_for_records(notes, &Note.changeset/2, fn note ->
      new_day_index =
        case note.day_index do
          nil -> nil
          day_index -> remap_day_index(day_index, from_day_index, to_day_index)
        end

      changed_attrs(note, %{day_index: new_day_index})
    end)
  end

  defp move_day_for_records(records, changeset_fun, attrs_fun) do
    Enum.reduce_while(records, :ok, fn record, :ok ->
      attrs = attrs_fun.(record)

      if map_size(attrs) == 0 do
        {:cont, :ok}
      else
        case Repo.update(changeset_fun.(record, attrs)) do
          {:ok, _updated_record} -> {:cont, :ok}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end
    end)
  end

  defp changed_attrs(record, attrs) do
    Enum.reduce(attrs, %{}, fn {key, value}, acc ->
      if Map.get(record, key) == value do
        acc
      else
        Map.put(acc, key, value)
      end
    end)
  end

  defp remap_day_index(day_index, from_day_index, to_day_index) when day_index == from_day_index,
    do: to_day_index

  defp remap_day_index(day_index, from_day_index, to_day_index)
       when from_day_index < to_day_index and day_index > from_day_index and
              day_index <= to_day_index,
       do: day_index - 1

  defp remap_day_index(day_index, from_day_index, to_day_index)
       when from_day_index > to_day_index and day_index >= to_day_index and
              day_index < from_day_index,
       do: day_index + 1

  defp remap_day_index(day_index, _from_day_index, _to_day_index), do: day_index

  defp normalize_day_range(start_day, end_day) when start_day <= end_day, do: {start_day, end_day}
  defp normalize_day_range(start_day, end_day), do: {end_day, start_day}

  defp paginate(query, page, page_size, preload_callback) when is_function(preload_callback, 1) do
    page = normalize_page(page)
    page_size = normalize_page_size(page_size)
    total_entries = Repo.aggregate(query, :count, :id)
    total_pages = total_pages(total_entries, page_size)
    current_page = min(page, total_pages)

    entries =
      query
      |> limit(^page_size)
      |> offset(^((current_page - 1) * page_size))
      |> Repo.all()
      |> preload_callback.()

    %{
      entries: entries,
      page: current_page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    }
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  defp normalize_page_size(page_size) when is_integer(page_size) and page_size > 0, do: page_size
  defp normalize_page_size(_), do: @default_page_size

  defp total_pages(total_entries, page_size) do
    max(1, div(total_entries + page_size - 1, page_size))
  end

  defp authorize_participant_management(%Trip{} = trip, %User{} = actor) do
    if Policy.participant?(trip, actor) do
      :ok
    else
      {:error, :not_participant}
    end
  end

  defp validate_addable_participant(%Trip{} = trip, participant_id) do
    participant_ids =
      trip.trip_participants
      |> Enum.map(& &1.user_id)
      |> Kernel.++([trip.author_id])

    author_friend_ids = Social.list_friend_ids(trip.author_id)

    cond do
      participant_id == trip.author_id ->
        {:error, :author_cannot_be_added}

      participant_id in participant_ids ->
        {:error, :already_participant}

      participant_id not in author_friend_ids ->
        {:error, :not_in_author_friend_circle}

      true ->
        :ok
    end
  end

  defp create_trip_participant(%Trip{} = trip, participant_id) do
    %TripParticipant{}
    |> TripParticipant.changeset(%{trip_id: trip.id, user_id: participant_id})
    |> Repo.insert()
    |> case do
      {:ok, trip_participant} ->
        {:ok, trip_participant}

      {:error, changeset} ->
        cond do
          has_constraint_error?(changeset, :trip_id, :foreign) ->
            {:error, :trip_not_found}

          has_constraint_error?(changeset, :user_id, :foreign) ->
            {:error, :user_not_found}

          true ->
            {:error, changeset}
        end
    end
  end

  defp authorize_participant_removal(%Trip{} = trip, %User{} = actor, participant_id) do
    cond do
      participant_id == trip.author_id ->
        {:error, :cannot_remove_author}

      actor.id == trip.author_id ->
        :ok

      actor.id == participant_id and Policy.participant?(trip, actor) ->
        :ok

      true ->
        {:error, :not_allowed}
    end
  end

  defp delete_trip_participant(%Trip{} = trip, participant_id) do
    case Repo.get_by(TripParticipant, trip_id: trip.id, user_id: participant_id) do
      %TripParticipant{} = trip_participant ->
        Repo.delete(trip_participant)

      nil ->
        {:error, :not_found}
    end
  end

  defp has_constraint_error?(%Ecto.Changeset{} = changeset, field, constraint_type) do
    Enum.any?(changeset.errors, fn
      {^field, {_message, opts}} -> Keyword.get(opts, :constraint) == constraint_type
      _ -> false
    end)
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
