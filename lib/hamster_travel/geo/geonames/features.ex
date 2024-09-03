defmodule HamsterTravel.Geo.Geonames.Features do
  alias HamsterTravel.Geo
  alias HamsterTravel.Geo.Country
  alias HamsterTravel.Geo.Geonames.{Client, FeaturesImporter, Translations}

  alias HamsterTravel.Repo

  require Logger

  def import(country_code) do
    download_translations = Task.async(fn -> Translations.fetch(country_code) end)

    with {:ok, features} <- Client.fetch_features_for_country(country_code),
         {:ok, translations} <- Task.await(download_translations, 60_000) do
      FeaturesImporter.process(features, country_code, translations)

      # update country with translation
      country = Geo.find_country_by_iso(country_code)
      update_country_translation(country, Map.get(translations, country.geonames_id))
    else
      _ ->
        nil
    end
  end

  defp update_country_translation(_, nil), do: nil

  defp update_country_translation(country, name_ru) do
    changeset = Country.changeset(country, %{name_ru: name_ru})
    Repo.update(changeset)
  end
end
