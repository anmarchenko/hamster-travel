defmodule HamsterTravel.GeoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Geo` context.
  """

  alias HamsterTravel.Geo.{City, Country, Geonames, Region}
  alias HamsterTravel.Geo.Geonames.{Countries, Features}
  alias HamsterTravel.Repo

  def geonames_fixture do
    Req.Test.stub(Geonames, fn conn ->
      case conn.request_path do
        "/export/dump/countryInfo.txt" ->
          Req.Test.text(conn, File.read!("test/support/test_data/geonames/countryInfo.txt"))

        "/export/dump/DE.zip" ->
          Req.Test.text(conn, File.read!("test/support/test_data/geonames/features_de.txt"))

        "/export/dump/alternatenames/DE.zip" ->
          Req.Test.text(
            conn,
            File.read!("test/support/test_data/geonames/alternate_names_de.txt")
          )
      end
    end)

    Countries.import()
    Features.import("DE")
  end

  def country_fixture(attrs \\ %{}) do
    iso = Map.get(attrs, :iso, "FR")
    country = Repo.get_by!(Country, iso: iso)
    changes = Map.delete(attrs, :iso)

    if map_size(changes) == 0 do
      country
    else
      country
      |> Ecto.Changeset.change(changes)
      |> Repo.update!()
    end
  end

  def region_fixture(%Country{} = country, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Ile-de-France",
        name_ru: "Иль-де-Франс",
        region_code: "IDF",
        geonames_id: "3012874",
        country_code: country.iso,
        lat: 48.8499,
        lon: 2.6370
      })

    %Region{}
    |> Region.changeset(attrs)
    |> Repo.insert!()
  end

  def city_fixture(%Country{} = country, %Region{} = region, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Paris",
        name_ru: "Париж",
        geonames_id: "2988507",
        country_code: country.iso,
        region_code: region.region_code,
        lat: 48.8566,
        lon: 2.3522,
        population: 2_100_000
      })

    %City{}
    |> City.changeset(attrs)
    |> Repo.insert!()
  end
end
