defmodule HamsterTravel.Repo.Migrations.BackfillTripFoodBudgetCategories do
  use Ecto.Migration

  def up do
    alter table(:budget_category_food_settings) do
      add :calculation_mode, :string, null: false, default: "per_day"
    end

    execute("""
    INSERT INTO budget_categories (name, kind, trip_id, inserted_at, updated_at)
    SELECT 'Food', 'food', trips.id, NOW(), NOW()
    FROM trips
    WHERE NOT EXISTS (
      SELECT 1
      FROM budget_categories
      WHERE budget_categories.trip_id = trips.id
        AND budget_categories.kind = 'food'
    )
    """)

    execute("""
    UPDATE expenses
    SET budget_category_id = food_categories.id,
        budget_role = 'category_estimate',
        name = 'Food',
        updated_at = NOW()
    FROM food_expenses
    JOIN budget_categories AS food_categories
      ON food_categories.trip_id = food_expenses.trip_id
     AND food_categories.kind = 'food'
    WHERE expenses.food_expense_id = food_expenses.id
      AND expenses.budget_category_id IS NULL
    """)

    execute("""
    INSERT INTO budget_category_food_settings (
      price_per_day,
      days_count,
      people_count,
      calculation_mode,
      budget_category_id,
      inserted_at,
      updated_at
    )
    SELECT
      food_expenses.price_per_day,
      food_expenses.days_count,
      food_expenses.people_count,
      'per_day',
      food_categories.id,
      NOW(),
      NOW()
    FROM food_expenses
    JOIN budget_categories AS food_categories
      ON food_categories.trip_id = food_expenses.trip_id
     AND food_categories.kind = 'food'
    WHERE NOT EXISTS (
      SELECT 1
      FROM budget_category_food_settings
      WHERE budget_category_food_settings.budget_category_id = food_categories.id
    )
    """)

    create unique_index(:budget_categories, [:trip_id],
             name: :budget_categories_trip_food_index,
             where: "kind = 'food'"
           )
  end

  def down do
    drop index(:budget_categories, [:trip_id], name: :budget_categories_trip_food_index)

    alter table(:budget_category_food_settings) do
      remove :calculation_mode
    end
  end
end
