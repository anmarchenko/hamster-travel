defmodule HamsterTravel.Geo.Geonames.Countries do
  alias HamsterTravel.Geo.Geonames.{Client, CountriesImporter}
  require Logger

  def import do
    case Client.fetch_countries() do
      {:ok, countries} ->
        CountriesImporter.process(countries)

      _ ->
        nil
    end
  end
end
