defmodule HamsterTravel.GeoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Geo` context.
  """

  alias HamsterTravel.Geo.Geonames

  def geonames_countries_fixture do
    Req.Test.stub(Geonames, fn conn ->
      Req.Test.text(conn, File.read!("test/support/test_data/geonames/countryInfo.txt"))
    end)

    Geonames.import_countries()
  end
end
