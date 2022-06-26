defmodule HamsterTravel.Repo.Migrations.CreateBackpackItems do
  use Ecto.Migration

  def change do
    create table(:backpack_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :checked, :boolean, default: false, null: false
      add :count, :integer, null: false

      add :backpack_list_id,
          references(:backpack_lists, on_delete: :delete_all, type: :binary_id),
          null: false

      timestamps()
    end

    create index(:backpack_items, [:backpack_list_id])
  end
end
