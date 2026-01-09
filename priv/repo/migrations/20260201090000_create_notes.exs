defmodule HamsterTravel.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :title, :string, null: false
      add :text, :text
      add :day_index, :integer
      add :rank, :integer

      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:notes, [:trip_id])
    create index(:notes, [:trip_id, :day_index])
  end
end
