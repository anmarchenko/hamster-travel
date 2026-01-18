defmodule HamsterTravel.Planning.DayExpenses do
  @moduledoc false

  import Ecto.Query, warn: false

  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Planning.DayExpense
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

  def get_day_expense!(id) do
    Repo.get!(DayExpense, id)
    |> preloading()
  end

  def list_day_expenses(%Trip{id: trip_id}) do
    list_day_expenses(trip_id)
  end

  def list_day_expenses(trip_id) do
    Repo.all(
      from de in DayExpense,
        where: de.trip_id == ^trip_id,
        order_by: [asc: de.day_index, asc: de.rank]
    )
    |> preloading()
  end

  def create_day_expense(trip, attrs \\ %{}) do
    attrs =
      case Map.get(attrs, "expense") do
        nil -> attrs
        expense_attrs -> Map.put(attrs, "expense", Map.put(expense_attrs, "trip_id", trip.id))
      end

    %DayExpense{trip_id: trip.id}
    |> DayExpense.changeset(attrs)
    |> Repo.insert()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:day_expense, :created], trip.id)
  end

  def update_day_expense(%DayExpense{} = day_expense, attrs) do
    day_expense
    |> DayExpense.changeset(attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:day_expense, :updated], day_expense.trip_id)
  end

  def new_day_expense(trip, day_index, attrs \\ %{}) do
    %DayExpense{
      trip_id: trip.id,
      day_index: day_index,
      expense: %Expense{price: Money.new(trip.currency, 0)}
    }
    |> DayExpense.changeset(attrs)
  end

  def change_day_expense(%DayExpense{} = day_expense, attrs \\ %{}) do
    DayExpense.changeset(day_expense, attrs)
  end

  def delete_day_expense(%DayExpense{} = day_expense) do
    Repo.delete(day_expense)
    |> PubSub.broadcast([:day_expense, :deleted], day_expense.trip_id)
  end

  def move_day_expense_to_day(day_expense, new_day_index, trip, user, position \\ :last)

  def move_day_expense_to_day(nil, _new_day_index, _trip, _user, _position),
    do: {:error, "Day expense not found"}

  def move_day_expense_to_day(day_expense, new_day_index, trip, user, position) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_day_expense_belongs_to_trip(day_expense, trip),
         :ok <- Common.validate_day_index_in_trip_duration(new_day_index, trip.duration) do
      update_day_expense_position(day_expense, %{day_index: new_day_index, position: position})
    end
  end

  def reorder_day_expense(nil, _position, _trip, _user), do: {:error, "Day expense not found"}

  def reorder_day_expense(day_expense, position, trip, user) do
    with :ok <- Policy.authorize_edit(trip, user),
         :ok <- validate_day_expense_belongs_to_trip(day_expense, trip) do
      update_day_expense_position(day_expense, %{position: position})
    end
  end

  def day_expenses_for_day(day_index, day_expenses) do
    Common.singular_items_for_day(day_index, day_expenses)
    |> Enum.sort_by(& &1.rank)
  end

  def preloading_query do
    [:expense]
  end

  defp validate_day_expense_belongs_to_trip(day_expense, %Trip{day_expenses: day_expenses}) do
    if Enum.any?(day_expenses, &(&1.id == day_expense.id)) do
      :ok
    else
      {:error, "Day expense not found"}
    end
  end

  defp update_day_expense_position(day_expense, attrs) do
    day_expense
    |> DayExpense.changeset(attrs)
    |> Repo.update(stale_error_field: :id)
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:day_expense, :updated], day_expense.trip_id)
  end

  defp preloading(query) do
    query
    |> Repo.preload(preloading_query())
  end
end
