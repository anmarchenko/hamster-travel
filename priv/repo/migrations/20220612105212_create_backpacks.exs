defmodule HamsterTravel.Repo.Migrations.CreateBackpacks do
  use Ecto.Migration

  def change do
    create table(:backpacks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :days, :integer, null: false
      add :people, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid), null: false

      timestamps()
    end

    create index(:backpacks, [:user_id])
  end
end
