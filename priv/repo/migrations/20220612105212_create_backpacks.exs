defmodule HamsterTravel.Repo.Migrations.CreateBackpacks do
  use Ecto.Migration

  def change do
    create table(:backpacks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :days, :integer
      add :people, :integer
      add :user, references(:users, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:backpacks, [:user])
  end
end
