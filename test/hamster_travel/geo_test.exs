defmodule HamsterTravel.GeoTest do
  use HamsterTravel.DataCase, async: true
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
      assert %Country{name: "Germany", name_ru: "Германия"} = Geo.find_country_by_iso("DE")
    end

    test "find_country_by_iso returns nil if the country with given iso does not exist" do
      assert Geo.find_country_by_iso("ZZ") == nil
    end

    test "list_country_iso_codes/0 returns all country ISO codes ordered alphabetically" do
      assert Enum.count(Geo.list_country_iso_codes()) == 246
      assert ["AD", "AE", "AF"] == Enum.take(Geo.list_country_iso_codes(), 3)
    end

    test "find_region_by_code_and_country/2" do
      assert %Region{name: "Saxony", name_ru: "Саксония"} =
               Geo.find_region_by_code_and_country("13", "DE")

      assert Geo.find_region_by_code_and_country("xx", "DE") == nil
    end

    test "search_cities/1" do
      assert [
               %City{
                 name: "Berlin",
                 region_name: "Land Berlin",
                 name_ru: "Берлин",
                 region_name_ru: "Берлин"
               },
               %City{name: "Bergedorf", region_name: "Free and Hanseatic City of Hamburg"},
               %City{name: "Bergisch Gladbach", region_name: "Nordrhein-Westfalen"}
             ] = Geo.search_cities("ber")

      assert [
               %City{name: "Bergedorf", region_name: "Free and Hanseatic City of Hamburg"},
               %City{name: "Bergisch Gladbach", region_name: "Nordrhein-Westfalen"}
             ] = Geo.search_cities("berg")

      assert [] = Geo.search_cities("berr")
    end

    test "search_cities/1 in russian" do
      assert [
               %City{
                 name: "Berlin",
                 region_name: "Land Berlin",
                 name_ru: "Берлин",
                 region_name_ru: "Берлин"
               }
             ] = Geo.search_cities("бер")

      assert [] = Geo.search_cities("берр")
    end

    test "get_city/1 returns the city with preloaded country and region fields" do
      # Get a city from the imported geonames_fixture
      berlin = Geo.find_city_by_geonames_id("2950159")

      result = Geo.get_city(berlin.id)
      assert result.id == berlin.id
      assert "Germany" == result.country.name
      assert "Германия" == result.country.name_ru
      assert "Land Berlin" == result.region_name
      assert "Берлин" == result.region_name_ru
    end

    test "get_city/1 returns nil if the city does not exist" do
      assert Geo.get_city(-1) == nil
    end
  end
end
