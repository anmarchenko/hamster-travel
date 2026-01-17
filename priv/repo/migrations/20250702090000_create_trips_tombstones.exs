defmodule HamsterTravel.Repo.Migrations.CreateTripsTombstones do
  use Ecto.Migration

  def change do
    create table(:trips_tombstones, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :original_slug, :string, null: false
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :payload, :map, null: false
      add :payload_version, :integer, null: false, default: 1

      timestamps()
    end

    create index(:trips_tombstones, [:original_slug])
    create index(:trips_tombstones, [:author_id])
  end
end
