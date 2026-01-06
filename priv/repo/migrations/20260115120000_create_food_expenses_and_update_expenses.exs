defmodule HamsterTravel.Repo.Migrations.CreateFoodExpensesAndUpdateExpenses do
  use Ecto.Migration

  def up do
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
    INSERT INTO food_expenses (price_per_day, days_count, people_count, trip_id, inserted_at, updated_at)
    SELECT ROW(t.currency, 0)::money_with_currency,
           COALESCE(t.duration, 1),
           COALESCE(t.people_count, 1),
           t.id,
           NOW(),
           NOW()
    FROM trips t;
    """)

    execute("""
    INSERT INTO expenses (price, trip_id, food_expense_id, inserted_at, updated_at)
    SELECT ROW(t.currency, 0)::money_with_currency,
           t.id,
           fe.id,
           NOW(),
           NOW()
    FROM food_expenses fe
    JOIN trips t ON t.id = fe.trip_id;
    """)
  end

  def down do
    drop index(:expenses, [:food_expense_id])

    alter table(:expenses) do
      remove :food_expense_id
    end

    drop table(:food_expenses)
  end
end
