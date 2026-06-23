defmodule HamsterTravel.Repo.Migrations.RemoveFoodExpenses do
  use Ecto.Migration

  def up do
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

    drop index(:expenses, [:food_expense_id])

    alter table(:expenses) do
      remove :food_expense_id
    end

    drop table(:food_expenses)
  end

  def down do
    create table(:food_expenses) do
      add :price_per_day, :money_with_currency, null: false
      add :days_count, :integer, null: false
      add :people_count, :integer, null: false
      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:food_expenses, [:trip_id])

    alter table(:expenses) do
      add :food_expense_id, references(:food_expenses, on_delete: :delete_all)
    end

    create index(:expenses, [:food_expense_id])

    execute("""
    INSERT INTO food_expenses (
      price_per_day,
      days_count,
      people_count,
      trip_id,
      inserted_at,
      updated_at
    )
    SELECT
      food_settings.price_per_day,
      food_settings.days_count,
      food_settings.people_count,
      food_categories.trip_id,
      NOW(),
      NOW()
    FROM budget_categories AS food_categories
    JOIN budget_category_food_settings AS food_settings
      ON food_settings.budget_category_id = food_categories.id
    WHERE food_categories.kind = 'food'
    """)

    execute("""
    UPDATE expenses
    SET food_expense_id = food_expenses.id
    FROM food_expenses
    JOIN budget_categories AS food_categories
      ON food_categories.trip_id = food_expenses.trip_id
     AND food_categories.kind = 'food'
    WHERE expenses.budget_category_id = food_categories.id
      AND expenses.budget_role = 'category_estimate'
    """)
  end
end
