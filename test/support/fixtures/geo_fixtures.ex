defmodule HamsterTravel.GeoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Geo` context.
  """

  alias HamsterTravel.Geo.Geonames

  def geonames_fixture do
    Req.Test.stub(Geonames, fn conn ->
      case conn.request_path do
        "/export/dump/countryInfo.txt" ->
          Req.Test.text(conn, File.read!("test/support/test_data/geonames/countryInfo.txt"))

        "/export/dump/DE.zip" ->
          Req.Test.text(conn, File.read!("test/support/test_data/geonames/features_de.txt"))
      end
    end)

    Geonames.import_countries()
    Geonames.import_features("DE")
  end
end
