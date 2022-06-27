defmodule HamsterTravel.Repo.Migrations.AddSlugToBackpacks do
  use Ecto.Migration

  def change do
    alter table("backpacks") do
      add :slug, :string, null: false
    end

    create unique_index(:backpacks, [:slug])
  end
end
