defmodule HamsterTravel.GeoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Geo` context.
  """

  alias HamsterTravel.Geo.Geonames

  def geonames_countries_fixture do
    Req.Test.stub(Geonames, fn conn ->
      Req.Test.text(conn, File.read!("test/support/test_data/geonames/countryInfo.txt"))
    end)

    Geonames.import_countries()
  end

  @doc """
  Generate a region.
  """
  def region_fixture(attrs \\ %{}) do
    {:ok, region} =
      attrs
      |> Enum.into(%{
        country_code: "some country_code",
        geonames_id: "some geonames_id",
        lat: 120.5,
        lon: 120.5,
        name: "some name",
        name_ru: "some name_ru",
        region_code: "some region_code"
      })
      |> HamsterTravel.Geo.create_region()

    region
  end

  @doc """
  Generate a city.
  """
  def city_fixture(attrs \\ %{}) do
    {:ok, city} =
      attrs
      |> Enum.into(%{
        country_code: "some country_code",
        geonames_id: "some geonames_id",
        lat: 120.5,
        lon: 120.5,
        name: "some name",
        name_ru: "some name_ru",
        population: 42,
        region_code: "some region_code"
      })
      |> HamsterTravel.Geo.create_city()

    city
  end
end
