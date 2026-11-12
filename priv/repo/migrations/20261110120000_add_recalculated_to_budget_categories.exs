defmodule HamsterTravel.Repo.Migrations.AddRecalculatedToBudgetCategories do
  use Ecto.Migration

  def change do
    alter table(:budget_categories) do
      add :recalculated, :boolean, null: false, default: false
    end
  end
end
