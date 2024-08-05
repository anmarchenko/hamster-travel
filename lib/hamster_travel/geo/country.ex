defmodule HamsterTravel.Geo.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :name, :string
    field :name_ru, :string
    field :iso, :string
    field :geonames_id, :string
    field :continent, :string
    field :currency_code, :string
    field :currency_name, :string
    field :iso3, :string
    field :ison, :string

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [
      :name,
      :name_ru,
      :iso,
      :geonames_id,
      :continent,
      :currency_code,
      :currency_name,
      :iso3,
      :ison
    ])
    |> validate_required([
      :name,
      :iso,
      :geonames_id,
      :continent,
      :iso3,
      :ison
    ])
  end
end
