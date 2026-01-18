defmodule HamsterTravel.Planning.Expenses do
  @moduledoc false

  import Ecto.Query, warn: false

  require Logger

  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

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
    |> PubSub.broadcast([:expense, :created], trip.id)
  end

  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.changeset(attrs)
    |> Repo.update()
    |> PubSub.broadcast([:expense, :updated], expense.trip_id)
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
    |> PubSub.broadcast([:expense, :deleted], expense.trip_id)
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
end
