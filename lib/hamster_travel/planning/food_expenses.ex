defmodule HamsterTravel.Planning.FoodExpenses do
  @moduledoc false

  alias HamsterTravel.Planning.Common
  alias HamsterTravel.Planning.FoodExpense
  alias HamsterTravel.Planning.PubSub
  alias HamsterTravel.Repo

  def get_food_expense!(id) do
    Repo.get!(FoodExpense, id)
    |> preloading()
  end

  def update_food_expense(%FoodExpense{} = food_expense, attrs) do
    food_expense = Repo.preload(food_expense, [:trip, :expense])

    food_expense
    |> FoodExpense.build_food_expense_changeset(food_expense.trip, attrs)
    |> Repo.update()
    |> Common.preload_after_db_call(&preloading(&1))
    |> PubSub.broadcast([:food_expense, :updated], food_expense.trip_id)
  end

  def change_food_expense(%FoodExpense{} = food_expense, attrs \\ %{}) do
    FoodExpense.changeset(food_expense, attrs)
  end

  def default_food_expense_attrs(trip) do
    %{
      price_per_day: Money.new(trip.currency, 0),
      days_count: trip.duration || 1,
      people_count: trip.people_count || 1
    }
  end

  def create_food_expense_with_repo(repo, trip, attrs) do
    %FoodExpense{trip_id: trip.id}
    |> FoodExpense.build_food_expense_changeset(trip, attrs)
    |> repo.insert()
  end

  defp preloading(query) do
    Repo.preload(query, [:expense])
  end
end
