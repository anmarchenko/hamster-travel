defmodule Geo.Geonames do
  @moduledoc """
  Handles downloading, parsing, and importing geonames data.
  """
  alias HamsterTravel.Geo.Country

  require Logger

  def import_countries do
    {:ok, countries} = download_countries()

    countries
    |> String.split("\r\n")
    |> Enum.reject(&String.starts_with?(&1, "#"))
    |> Enum.map(&String.split(&1, "\t"))
    |> Enum.map(&parse_country/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn country -> country.population <= 0 end)
  end

  defp download_countries do
    case Req.get("https://download.geonames.org/export/dump/countryInfo.txt") do
      {:ok, %Req.Response{body: body} = resp} ->
        if resp.status < 400 do
          {:ok, body}
        else
          :telemetry.execute(
            [:hamster_travel, :geonames, :download_countries],
            %{error: 1},
            %{
              reason: "status_#{resp.status}"
            }
          )

          Logger.error("Failed to download countries: #{inspect(resp)}")
          {:error, "HTTP error: #{resp.status}"}
        end

      {:error, reason} = error_tuple ->
        :telemetry.execute(
          [:hamster_travel, :geonames, :download_countries],
          %{error: 1},
          %{
            reason: "network"
          }
        )

        Logger.error("Failed to download countries: #{inspect(reason)}")
        error_tuple
    end
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
    %Country{
      geonames_id: geonames_id,
      iso: iso,
      iso3: iso3,
      ison: ison,
      name: name,
      continent: continent,
      currency_code: currency_code,
      currency_name: currency_name,
      population: String.to_integer(population)
    }
  end

  defp parse_country(_) do
    nil
  end
end
