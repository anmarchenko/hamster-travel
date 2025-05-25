defmodule HamsterTravel.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses) do
      add :price, :money_with_currency, null: false
      add :name, :string

      add :trip_id, references(:trips, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:expenses, [:trip_id])
  end
end
