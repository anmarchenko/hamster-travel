defmodule HamsterTravel.Planning.FoodExpenseTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Planning.FoodExpense
  import HamsterTravel.PlanningFixtures

  describe "changeset/2" do
    test "requires price_per_day, days_count, people_count, trip_id" do
      changeset = FoodExpense.changeset(%FoodExpense{}, %{})
      refute changeset.valid?

      assert %{
               price_per_day: ["can't be blank"],
               days_count: ["can't be blank"],
               people_count: ["can't be blank"],
               trip_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates positive counts" do
      trip = trip_fixture()

      changeset =
        FoodExpense.changeset(%FoodExpense{}, %{
          price_per_day: Money.new(:EUR, 1000),
          days_count: 0,
          people_count: -1,
          trip_id: trip.id
        })

      assert %{
               days_count: ["must be greater than 0"],
               people_count: ["must be greater than 0"]
             } = errors_on(changeset)
    end
  end

  describe "food_expense_total/2" do
    test "calculates total for integer inputs" do
      trip = trip_fixture()

      changeset =
        FoodExpense.changeset(%FoodExpense{trip_id: trip.id}, %{
          price_per_day: Money.new(:EUR, 250),
          days_count: 2,
          people_count: 4,
          trip_id: trip.id
        })

      assert FoodExpense.food_expense_total(changeset, trip.currency) ==
               Money.new(:EUR, 250) |> Money.mult!(2) |> Money.mult!(4)
    end

    test "normalizes string counts" do
      trip = trip_fixture()

      changeset =
        FoodExpense.changeset(%FoodExpense{trip_id: trip.id}, %{
          price_per_day: Money.new(:EUR, 300),
          days_count: "3",
          people_count: "2",
          trip_id: trip.id
        })

      assert FoodExpense.food_expense_total(changeset, trip.currency) ==
               Money.new(:EUR, 300) |> Money.mult!(3) |> Money.mult!(2)
    end

    test "falls back to zero when price_per_day is nil" do
      trip = trip_fixture()

      changeset =
        FoodExpense.changeset(%FoodExpense{trip_id: trip.id}, %{
          price_per_day: nil,
          days_count: 2,
          people_count: 2,
          trip_id: trip.id
        })

      assert FoodExpense.food_expense_total(changeset, trip.currency) == Money.new(:EUR, 0)
    end
  end

  describe "build_food_expense_changeset/3" do
    test "builds expense association with total price" do
      trip = trip_fixture()
      food_expense = %FoodExpense{trip_id: trip.id}

      changeset =
        FoodExpense.build_food_expense_changeset(food_expense, trip, %{
          price_per_day: Money.new(:EUR, 1000),
          days_count: 2,
          people_count: 2,
          trip_id: trip.id
        })

      expected = Money.new(:EUR, 1000) |> Money.mult!(2) |> Money.mult!(2)

      assert %Ecto.Changeset{} =
               expense_changeset = Ecto.Changeset.get_change(changeset, :expense)

      assert expense_changeset.changes.price == expected
      assert expense_changeset.changes.trip_id == trip.id
    end

    test "uses a new expense when association is not loaded" do
      trip = trip_fixture()

      not_loaded = %Ecto.Association.NotLoaded{
        __cardinality__: :one,
        __field__: :expense,
        __owner__: FoodExpense
      }

      food_expense = %FoodExpense{trip_id: trip.id, expense: not_loaded}

      changeset =
        FoodExpense.build_food_expense_changeset(food_expense, trip, %{
          price_per_day: Money.new(:EUR, 500),
          days_count: 1,
          people_count: 2,
          trip_id: trip.id
        })

      expected = Money.new(:EUR, 500) |> Money.mult!(2)

      assert %Ecto.Changeset{} =
               expense_changeset = Ecto.Changeset.get_change(changeset, :expense)

      assert expense_changeset.changes.price == expected
      assert expense_changeset.changes.trip_id == trip.id
    end

    test "uses provided trip currency for price defaults" do
      trip = trip_fixture(%{currency: "USD"})
      food_expense = %FoodExpense{trip_id: trip.id}

      changeset =
        FoodExpense.build_food_expense_changeset(food_expense, trip, %{
          price_per_day: nil,
          days_count: 2,
          people_count: 2,
          trip_id: trip.id
        })

      assert %Ecto.Changeset{} =
               expense_changeset = Ecto.Changeset.get_change(changeset, :expense)

      assert expense_changeset.changes.price == Money.new(:USD, 0)
    end
  end
end
