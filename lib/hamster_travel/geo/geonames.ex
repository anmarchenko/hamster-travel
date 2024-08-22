defmodule HamsterTravel.Geo.Geonames do
  @moduledoc """
  Handles downloading, parsing, and importing geonames data.
  """
  alias HamsterTravel.Geo
  alias HamsterTravel.Geo.Geonames.{Countries, Features}

  require Logger

  def import do
    Logger.info("Starting geonames data import...")

    Countries.import()

    Enum.each(Geo.list_country_iso_codes(), &Features.import/1)
  end
end
