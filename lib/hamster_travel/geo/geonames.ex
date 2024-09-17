defmodule HamsterTravel.Geo.Geonames do
  @moduledoc """
  Handles downloading, parsing, and importing geonames data.
  """
  alias HamsterTravel.Geo
  alias HamsterTravel.Geo.Geonames.{Countries, Features}

  require Logger

  def import do
    Logger.info("Starting geonames data import...")

    # import countries first
    Countries.import()

    # import features (regions and cities) and translations for each country
    Enum.each(Geo.list_country_iso_codes(), fn country_code ->
      Features.import(country_code)
    end)
  end
end
