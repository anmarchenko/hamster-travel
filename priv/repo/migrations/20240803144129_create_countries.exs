defmodule HamsterTravel.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string, null: false
      add :name_ru, :string
      add :iso, :string, null: false
      add :geonames_id, :string, null: false
      add :continent, :string, null: false
      add :currency_code, :string
      add :currency_name, :string
      add :iso3, :string, null: false
      add :ison, :string, null: false

      timestamps()
    end

    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX countries_name_gin_trgm_idx
        ON countries
        USING gin (name gin_trgm_ops);
    """

    execute """
      CREATE INDEX countries_name_ru_gin_trgm_idx
        ON countries
        USING gin (name_ru gin_trgm_ops);
    """

    create unique_index(:countries, [:geonames_id])
    create unique_index(:countries, [:iso])
  end
end
