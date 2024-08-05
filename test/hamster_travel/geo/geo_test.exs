defmodule HamsterTravel.GeoTest do
  use HamsterTravel.DataCase
  import HamsterTravel.GeoFixtures

  alias HamsterTravel.Geo

  describe "countries" do
    setup do
      geonames_countries_fixture()

      :ok
    end

    test "list_countries/0 returns all countries imported from geonames" do
      assert Enum.count(Geo.list_countries()) == 246
    end

    test "get_country!/1 returns the country with given id" do
      [country | _] = Geo.list_countries()
      assert Geo.get_country!(country.id) == country
    end
  end
end
