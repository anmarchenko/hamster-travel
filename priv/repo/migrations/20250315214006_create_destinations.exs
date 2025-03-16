defmodule HamsterTravel.Repo.Migrations.CreateDestinations do
  use Ecto.Migration

  def change do
    create table(:destinations) do
      add :start_day, :integer
      add :end_day, :integer

      add :trip_id, references(:trips, on_delete: :nothing, type: :binary_id)
      add :city_id, references(:cities, on_delete: :nothing)

      timestamps()
    end

    create index(:destinations, [:trip_id])
    create index(:destinations, [:city_id])
    create index(:destinations, [:trip_id, :start_day, :end_day])
  end
end
