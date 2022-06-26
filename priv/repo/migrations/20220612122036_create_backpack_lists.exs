defmodule HamsterTravel.Repo.Migrations.CreateBackpackLists do
  use Ecto.Migration

  def change do
    create table(:backpack_lists, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :backpack_id, references(:backpacks, on_delete: :delete_all, type: :uuid), null: false

      timestamps()
    end

    create index(:backpack_lists, [:backpack_id])
  end
end
