defmodule HamsterTravel.Repo.Migrations.CreateBudgetCategories do
  use Ecto.Migration

  def change do
    create table(:budget_categories) do
      add :name, :string, null: false
      add :kind, :string, null: false, default: "general"
      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:budget_categories, [:trip_id])
    create unique_index(:budget_categories, [:trip_id, :name])

    alter table(:expenses) do
      add :budget_category_id, references(:budget_categories, on_delete: :delete_all)
      add :budget_role, :string
    end

    create index(:expenses, [:budget_category_id])
    create index(:expenses, [:budget_category_id, :budget_role])

    create unique_index(:expenses, [:budget_category_id, :budget_role],
             name: :expenses_budget_category_estimate_index,
             where: "budget_role = 'category_estimate'"
           )

    create table(:budget_category_food_settings) do
      add :price_per_day, :money_with_currency, null: false
      add :days_count, :integer, null: false
      add :people_count, :integer, null: false
      add :budget_category_id, references(:budget_categories, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:budget_category_food_settings, [:budget_category_id])
  end
end
