defmodule HamsterTravel.GeoTest do
  use HamsterTravel.DataCase
  import HamsterTravel.GeoFixtures

  alias HamsterTravel.Geo

  describe "countries" do
    alias HamsterTravel.Geo.{City, Country, Region}

    setup do
      geonames_fixture()

      :ok
    end

    test "list_countries/0 returns all countries imported from geonames" do
      assert Enum.count(Geo.list_countries()) == 246
    end

    test "get_country!/1 returns the country with given id" do
      [country | _] = Geo.list_countries()
      assert Geo.get_country!(country.id) == country
    end

    test "find_country_by_geonames_id returns the country with given geonames_id" do
      [country | _] = Geo.list_countries()
      assert Geo.find_country_by_geonames_id(country.geonames_id) == country
    end

    test "find_country_by_geonames_id returns nil if the country with given geonames_id does not exist" do
      assert Geo.find_country_by_geonames_id("999999999") == nil
    end

    test "find_country_by_iso returns the country with given iso" do
      assert %Country{name: "Germany"} = Geo.find_country_by_iso("DE")
    end

    test "find_country_by_iso returns nil if the country with given iso does not exist" do
      assert Geo.find_country_by_iso("ZZ") == nil
    end

    test "list_country_iso_codes/0 returns all country ISO codes ordered alphabetically" do
      assert Enum.count(Geo.list_country_iso_codes()) == 246
      assert ["AD", "AE", "AF"] == Enum.take(Geo.list_country_iso_codes(), 3)
    end

    test "find_region_by_code_and_country/2" do
      assert %Region{name: "Baden-Württemberg"} = Geo.find_region_by_code_and_country("01", "DE")
      assert Geo.find_region_by_code_and_country("xx", "DE") == nil
    end

    test "search_cities/1" do
      assert [
               %City{name: "Berlin", region_name: "Land Berlin"},
               %City{name: "Bergedorf", region_name: "Free and Hanseatic City of Hamburg"},
               %City{name: "Bergisch Gladbach", region_name: "Nordrhein-Westfalen"}
             ] = Geo.search_cities("ber")

      assert [
               %City{name: "Bergedorf", region_name: "Free and Hanseatic City of Hamburg"},
               %City{name: "Bergisch Gladbach", region_name: "Nordrhein-Westfalen"}
             ] = Geo.search_cities("berg")

      assert [] = Geo.search_cities("berr")
    end
  end
end
