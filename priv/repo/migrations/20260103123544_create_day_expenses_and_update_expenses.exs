defmodule HamsterTravel.Repo.Migrations.CreateDayExpensesAndUpdateExpenses do
  use Ecto.Migration

  def change do
    create table(:day_expenses) do
      add :name, :string, null: false
      add :day_index, :integer, null: false
      add :rank, :integer

      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:day_expenses, [:trip_id])
    create index(:day_expenses, [:trip_id, :day_index])

    alter table(:expenses) do
      add :day_expense_id, references(:day_expenses, on_delete: :delete_all)
    end

    create index(:expenses, [:day_expense_id])
  end
end
