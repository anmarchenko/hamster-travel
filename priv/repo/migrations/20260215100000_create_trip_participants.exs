defmodule HamsterTravel.Repo.Migrations.CreateTripParticipants do
  use Ecto.Migration

  def change do
    create table(:trip_participants) do
      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:trip_participants, [:trip_id])
    create index(:trip_participants, [:user_id])
    create unique_index(:trip_participants, [:trip_id, :user_id])
  end
end
