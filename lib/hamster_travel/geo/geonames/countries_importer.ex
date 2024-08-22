defmodule HamsterTravel.Geo.Geonames.CountriesImporter do
  @non_existing_countries ["CS", "AN"]

  alias HamsterTravel.Geo.Country
  alias HamsterTravel.Repo

  require Logger

  def process(countries) do
    Logger.info("Importing countries...")

    countries =
      countries
      |> String.split("\n")
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.map(&String.split(String.trim(&1), "\t"))
      |> Enum.map(&parse_country/1)
      |> Enum.reject(fn country_data ->
        country_data == nil || Enum.member?(@non_existing_countries, country_data[:iso])
      end)

    {entries_count, _} =
      Repo.insert_all(
        Country,
        countries,
        on_conflict: {:replace_all_except, [:id, :inserted_at, :name_ru]},
        conflict_target: :geonames_id
      )

    Logger.info("Imported #{entries_count} countries")
  end

  defp parse_country([
         iso,
         iso3,
         ison,
         _,
         name,
         _,
         _,
         population,
         continent,
         _,
         currency_code,
         currency_name,
         _,
         _,
         _,
         _,
         geonames_id | _
       ]) do
    population = String.to_integer(population)

    if population <= 0 do
      Logger.info("Skipping country #{name} with population #{population}")

      nil
    else
      %{
        geonames_id: geonames_id,
        iso: iso,
        iso3: iso3,
        ison: ison,
        name: name,
        continent: continent,
        currency_code: currency_code,
        currency_name: currency_name,
        inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
        updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      }
    end
  end

  defp parse_country(_) do
    nil
  end
end
