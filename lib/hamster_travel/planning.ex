defmodule HamsterTravel.Planning do
  @moduledoc """
  The Planning context.
  """

  import Ecto.Query, warn: false

  require Logger

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Geo
  alias HamsterTravel.Planning.{Accommodation, Destination, Expense, Policy, Transfer, Trip}
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
    |> Repo.preload([:author, :countries, :expenses])
  end

  defp single_trip_preloading(query) do
    query
    |> Repo.preload([
      :author,
      :countries,
      accommodations: :expense,
      destinations: destinations_preloading_query(),
      transfers: transfers_preloading_query()
    ])
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
    |> Repo.preload(destinations_preloading_query())
  end

  defp destinations_preloading_query do
    [
      city: Geo.city_preloading_query()
    ]
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

  @doc """
  Calculates the total budget for a trip by summing all expenses.

  If expenses are not preloaded, they will be fetched from the database.
  Each expense is converted to the trip's currency before summing.
  Returns a Money struct in the trip's currency.

  ## Examples

      iex> trip = %Trip{currency: "EUR", expenses: [%Expense{price: Money.new(:EUR, 1000)}]}
      iex> calculate_budget(trip)
      %Money{amount: 1000, currency: :EUR}

  """
  def calculate_budget(%Trip{} = trip) do
    trip
    |> get_trip_expenses()
    |> Enum.map(&convert_expense_to_currency(&1, trip.currency))
    |> Enum.reduce(Money.new(trip.currency, 0), fn converted_price, acc ->
      case Money.add(acc, converted_price) do
        {:ok, result} -> result
        {:error, _} -> acc
      end
    end)
  end

  defp get_trip_expenses(%Trip{expenses: %Ecto.Association.NotLoaded{}} = trip) do
    list_expenses(trip.id)
  end

  defp get_trip_expenses(%Trip{expenses: expenses}), do: expenses

  defp convert_expense_to_currency(%Expense{price: price}, target_currency)
       when price.currency == target_currency,
       do: price

  defp convert_expense_to_currency(%Expense{price: price}, target_currency) do
    case Money.to_currency(price, target_currency) do
      {:ok, converted_money} ->
        converted_money

      {:error, _} ->
        Logger.error("Failed to convert expense to currency: #{inspect(price)}")

        Money.new(target_currency, 0)
    end
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

  defp singular_items_for_day(day_index, items) do
    Enum.filter(items, fn item ->
      item.day_index == day_index
    end)
  end

  defp preload_after_db_call({:error, _} = res, _preload_fun), do: res

  defp preload_after_db_call({:ok, record}, preload_fun) do
    record = preload_fun.(record)
    {:ok, record}
  end

  # Transfer functions

  def get_transfer!(id) do
    Repo.get!(Transfer, id)
    |> transfers_preloading()
  end

  def list_transfers(%Trip{id: trip_id}) do
    list_transfers(trip_id)
  end

  def list_transfers(trip_id) do
    Repo.all(from t in Transfer, where: t.trip_id == ^trip_id, order_by: [asc: t.departure_time])
    |> transfers_preloading()
  end

  def create_transfer(trip, attrs \\ %{}) do
    # Ensure the expense has trip_id if it exists in attrs
    attrs =
      case Map.get(attrs, "expense") do
        nil -> attrs
        expense_attrs -> Map.put(attrs, "expense", Map.put(expense_attrs, "trip_id", trip.id))
      end

    %Transfer{trip_id: trip.id}
    |> Transfer.changeset(attrs)
    |> Repo.insert()
    |> preload_after_db_call(&transfers_preloading(&1))
    |> send_pubsub_event([:transfer, :created], trip.id)
  end

  def update_transfer(%Transfer{} = transfer, attrs) do
    transfer
    |> Transfer.changeset(attrs)
    |> Repo.update()
    |> preload_after_db_call(&transfers_preloading(&1))
    |> send_pubsub_event([:transfer, :updated], transfer.trip_id)
  end

  def new_transfer(trip, day_index, attrs \\ %{}) do
    %Transfer{
      transport_mode: "flight",
      trip_id: trip.id,
      departure_city: nil,
      arrival_city: nil,
      day_index: day_index,
      expense: %Expense{price: Money.new(trip.currency, 0)}
    }
    |> Transfer.changeset(attrs)
  end

  def change_transfer(%Transfer{} = transfer, attrs \\ %{}) do
    Transfer.changeset(transfer, attrs)
  end

  def delete_transfer(%Transfer{} = transfer) do
    Repo.delete(transfer)
    |> send_pubsub_event([:transfer, :deleted], transfer.trip_id)
  end

  def move_transfer_to_day(nil, _new_day_index, _trip, _user), do: {:error, "Transfer not found"}

  def move_transfer_to_day(transfer, new_day_index, trip, user) do
    with :ok <- validate_user_authorization(trip, user),
         :ok <- validate_transfer_belongs_to_trip(transfer, trip),
         :ok <- validate_day_index_in_trip_duration(new_day_index, trip),
         {:ok, updated_transfer} <- update_transfer_day_index(transfer, new_day_index) do
      {:ok, updated_transfer}
    end
  end

  defp validate_user_authorization(%Trip{} = trip, %User{} = user) do
    if Policy.authorized?(:edit, trip, user) do
      :ok
    else
      {:error, "Unauthorized"}
    end
  end

  defp validate_transfer_belongs_to_trip(transfer, %Trip{transfers: transfers}) do
    if Enum.any?(transfers, &(&1.id == transfer.id)) do
      :ok
    else
      {:error, "Transfer not found"}
    end
  end

  defp validate_day_index_in_trip_duration(day_index, %Trip{duration: duration}) do
    if day_index >= 0 and day_index < duration do
      :ok
    else
      {:error, "Day index must be between 0 and #{duration - 1}"}
    end
  end

  defp update_transfer_day_index(transfer, new_day_index) do
    transfer
    |> Transfer.changeset(%{day_index: new_day_index})
    |> Repo.update(stale_error_field: :id)
    |> preload_after_db_call(&transfers_preloading(&1))
  end

  def transfers_for_day(day_index, transfers) do
    singular_items_for_day(day_index, transfers)
    |> Enum.sort_by(& &1.departure_time)
  end

  defp transfers_preloading(query) do
    query
    |> Repo.preload(transfers_preloading_query())
  end

  defp transfers_preloading_query do
    [
      :expense,
      departure_city: Geo.city_preloading_query(),
      arrival_city: Geo.city_preloading_query()
    ]
  end
end
