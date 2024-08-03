defmodule HamsterTravel.GeoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Geo` context.
  """

  @doc """
  Generate a country.
  """
  def country_fixture(attrs \\ %{}) do
    {:ok, country} =
      attrs
      |> Enum.into(%{
        continent: "some continent",
        currency_code: "some currency_code",
        currency_name: "some currency_name",
        geonames_id: "some geonames_id",
        iso: "some iso",
        iso3: "some iso3",
        ison: "some ison",
        name: "some name",
        name_ru: "some name_ru"
      })
      |> HamsterTravel.Geo.create_country()

    country
  end
end
