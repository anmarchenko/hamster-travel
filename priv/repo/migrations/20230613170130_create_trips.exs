defmodule HamsterTravel.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false

      add :dates_unknown, :boolean, default: false, null: false
      add :start_date, :date
      add :end_date, :date
      add :duration, :integer, null: false, default: 1

      add :currency, :string, null: false
      add :status, :string
      add :private, :boolean, default: false, null: false
      add :people_count, :integer, null: false, default: 1

      add :author_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:trips, [:author_id])
    create unique_index(:trips, [:slug])
  end
end
