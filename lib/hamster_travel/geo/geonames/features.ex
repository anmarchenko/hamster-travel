defmodule HamsterTravel.Geo.Geonames.Features do
  alias HamsterTravel.Geo.Geonames.{Client, FeaturesImporter, Translations}
  require Logger

  def import(country_code) do
    download_translations = Task.async(fn -> Translations.fetch(country_code) end)

    with {:ok, features} <- Client.fetch_features_for_country(country_code),
         {:ok, translations} <- Task.await(download_translations) do
      FeaturesImporter.process(features, country_code, translations)
    else
      _ ->
        nil
    end
  end
end
