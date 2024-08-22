defmodule HamsterTravel.Geo.Geonames.Features do
  alias HamsterTravel.Geo.Geonames.{Client, FeaturesImporter}
  require Logger

  def import(country_code) do
    case Client.fetch_features_for_country(country_code) do
      {:ok, features} ->
        FeaturesImporter.process(features, country_code)

      _ ->
        nil
    end
  end
end
