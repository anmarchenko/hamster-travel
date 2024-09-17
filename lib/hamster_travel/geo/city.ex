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

    # Ecto does not support composite foreign keys as of Ecto 3.12.1
    # Wait till this is finally merged: https://github.com/elixir-ecto/ecto/pull/3638
    #
    # belongs_to :region, HamsterTravel.Geo.Region,
    #   foreign_key: :region_code,
    #   references: :region_code,
    #   type: :string
    field :region_code, :string

    # define virtual fields for region_name and region_name_ru
    field :region_name, :string, virtual: true
    field :region_name_ru, :string, virtual: true

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
