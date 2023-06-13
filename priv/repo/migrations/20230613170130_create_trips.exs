defmodule HamsterTravel.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def change do
    create table(:trips, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :dates_unknown, :boolean, default: false, null: false
      add :duration, :integer
      add :start_date, :date
      add :end_date, :date
      add :currency, :string
      add :status, :string
      add :private, :boolean, default: false, null: false
      add :people_count, :integer
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:trips, [:author_id])
  end
end
