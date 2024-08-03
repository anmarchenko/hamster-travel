defmodule HamsterTravel.GeoTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Geo

  describe "countries" do
    alias HamsterTravel.Geo.Country

    import HamsterTravel.GeoFixtures

    @invalid_attrs %{
      name: nil,
      name_ru: nil,
      iso: nil,
      geonames_id: nil,
      continent: nil,
      currency_code: nil,
      currency_name: nil,
      iso3: nil,
      ison: nil
    }

    test "list_countries/0 returns all countries" do
      country = country_fixture()
      assert Geo.list_countries() == [country]
    end

    test "get_country!/1 returns the country with given id" do
      country = country_fixture()
      assert Geo.get_country!(country.id) == country
    end

    test "create_country/1 with valid data creates a country" do
      valid_attrs = %{
        name: "some name",
        name_ru: "some name_ru",
        iso: "some iso",
        geonames_id: "some geonames_id",
        continent: "some continent",
        currency_code: "some currency_code",
        currency_name: "some currency_name",
        iso3: "some iso3",
        ison: "some ison"
      }

      assert {:ok, %Country{} = country} = Geo.create_country(valid_attrs)
      assert country.name == "some name"
      assert country.name_ru == "some name_ru"
      assert country.iso == "some iso"
      assert country.geonames_id == "some geonames_id"
      assert country.continent == "some continent"
      assert country.currency_code == "some currency_code"
      assert country.currency_name == "some currency_name"
      assert country.iso3 == "some iso3"
      assert country.ison == "some ison"
    end

    test "create_country/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Geo.create_country(@invalid_attrs)
    end

    test "update_country/2 with valid data updates the country" do
      country = country_fixture()

      update_attrs = %{
        name: "some updated name",
        name_ru: "some updated name_ru",
        iso: "some updated iso",
        geonames_id: "some updated geonames_id",
        continent: "some updated continent",
        currency_code: "some updated currency_code",
        currency_name: "some updated currency_name",
        iso3: "some updated iso3",
        ison: "some updated ison"
      }

      assert {:ok, %Country{} = country} = Geo.update_country(country, update_attrs)
      assert country.name == "some updated name"
      assert country.name_ru == "some updated name_ru"
      assert country.iso == "some updated iso"
      assert country.geonames_id == "some updated geonames_id"
      assert country.continent == "some updated continent"
      assert country.currency_code == "some updated currency_code"
      assert country.currency_name == "some updated currency_name"
      assert country.iso3 == "some updated iso3"
      assert country.ison == "some updated ison"
    end

    test "update_country/2 with invalid data returns error changeset" do
      country = country_fixture()
      assert {:error, %Ecto.Changeset{}} = Geo.update_country(country, @invalid_attrs)
      assert country == Geo.get_country!(country.id)
    end

    test "delete_country/1 deletes the country" do
      country = country_fixture()
      assert {:ok, %Country{}} = Geo.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Geo.get_country!(country.id) end
    end

    test "change_country/1 returns a country changeset" do
      country = country_fixture()
      assert %Ecto.Changeset{} = Geo.change_country(country)
    end
  end
end
