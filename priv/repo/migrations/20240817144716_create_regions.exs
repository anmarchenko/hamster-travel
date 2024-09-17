defmodule HamsterTravel.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def change do
    create table(:regions) do
      add :name, :string, null: false
      add :name_ru, :string
      add :region_code, :string, null: false
      add :geonames_id, :string, null: false
      add :country_code, references("countries", column: :iso, type: :string), null: false
      add :lat, :float
      add :lon, :float

      timestamps()
    end

    create unique_index(:regions, [:geonames_id])
    create unique_index(:regions, [:country_code, :region_code])
  end
end
