defmodule HamsterTravel.Geo.City do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cities" do
    field :name, :string
    field :name_ru, :string
    field :geonames_id, :string
    field :lat, :float
    field :lon, :float
    field :population, :integer

    belongs_to :country, HamsterTravel.Geo.Country,
      foreign_key: :country_code,
      references: :iso,
      type: :string

    # TODO: will this work????
    belongs_to :region, HamsterTravel.Geo.Region,
      foreign_key: :region_code,
      references: :region_code,
      type: :string

    timestamps()
  end

  @doc false
  def changeset(city, attrs) do
    city
    |> cast(attrs, [
      :name,
      :name_ru,
      :region_code,
      :geonames_id,
      :country_code,
      :lat,
      :lon,
      :population
    ])
    |> validate_required([
      :name,
      :name_ru,
      :region_code,
      :geonames_id,
      :country_code,
      :lat,
      :lon,
      :population
    ])
  end
end
