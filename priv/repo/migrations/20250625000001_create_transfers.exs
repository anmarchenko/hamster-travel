defmodule HamsterTravel.Repo.Migrations.CreateTransfers do
  use Ecto.Migration

  def change do
    create table(:transfers) do
      add :transport_mode, :string, null: false
      add :departure_time, :utc_datetime, null: false
      add :arrival_time, :utc_datetime, null: false
      add :note, :text
      add :vessel_number, :string
      add :carrier, :string
      add :departure_station, :string
      add :arrival_station, :string

      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false
      add :departure_city_id, references(:cities, on_delete: :nothing), null: false
      add :arrival_city_id, references(:cities, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:transfers, [:trip_id])
    create index(:transfers, [:departure_city_id])
    create index(:transfers, [:arrival_city_id])
    create index(:transfers, [:transport_mode])
    create index(:transfers, [:departure_time])
  end
end
