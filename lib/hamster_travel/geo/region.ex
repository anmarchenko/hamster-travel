defmodule HamsterTravel.Geo.Region do
  use Ecto.Schema
  import Ecto.Changeset

  schema "regions" do
    field :name, :string
    field :name_ru, :string
    field :region_code, :string
    field :geonames_id, :string
    field :lat, :float
    field :lon, :float

    belongs_to :country, HamsterTravel.Geo.Country,
      foreign_key: :country_code,
      references: :iso,
      type: :string

    timestamps()
  end

  @doc false
  def changeset(region, attrs) do
    region
    |> cast(attrs, [:name, :name_ru, :region_code, :geonames_id, :country_code, :lat, :lon])
    |> validate_required([:name, :name_ru, :region_code, :geonames_id, :country_code, :lat, :lon])
  end
end
