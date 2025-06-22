defmodule HamsterTravel.Repo.Migrations.CreateAccommodations do
  use Ecto.Migration

  def change do
    create table(:accommodations) do
      add :name, :string, null: false
      add :link, :string
      add :address, :string
      add :note, :text
      add :start_day, :integer, null: false
      add :end_day, :integer, null: false

      add :trip_id, references(:trips, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:accommodations, [:trip_id])
    create index(:accommodations, [:trip_id, :start_day, :end_day])
  end
end
