defmodule HamsterTravel.Repo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :name, :string, null: false
      add :name_ru, :string

      add :region_code,
          references("regions",
            column: :region_code,
            type: :string,
            with: [country_code: :country_code]
          ),
          null: false

      add :geonames_id, :string, null: false
      add :country_code, references("countries", column: :iso, type: :string), null: false
      add :lat, :float
      add :lon, :float
      add :population, :integer, null: false

      timestamps()
    end

    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX cities_name_gin_trgm_idx
        ON cities
        USING gin (name gin_trgm_ops);
    """

    execute """
      CREATE INDEX cities_name_ru_gin_trgm_idx
        ON cities
        USING gin (name_ru gin_trgm_ops);
    """

    create unique_index(:cities, [:geonames_id])
  end
end
