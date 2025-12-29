defmodule HamsterTravel.Repo.Migrations.CreateActivitiesAndUpdateExpenses do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :name, :string, null: false
      add :day_index, :integer, null: false
      add :priority, :integer, null: false
      add :rank, :integer
      add :link, :string
      add :address, :string
      add :description, :text

      add :trip_id, references(:trips, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:activities, [:trip_id])
    create index(:activities, [:trip_id, :day_index])

    alter table(:expenses) do
      add :activity_id, references(:activities, on_delete: :delete_all)
    end

    create index(:expenses, [:activity_id])
  end
end