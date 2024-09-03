defmodule HamsterTravel.Geo.Geonames.Client do
  @base_url "https://download.geonames.org/export/dump"

  require Logger

  def fetch_countries do
    Logger.info("Downloading countries...")

    case Req.get("#{@base_url}/countryInfo.txt", options()) do
      {:ok, %Req.Response{body: body} = resp} ->
        if resp.status < 400 do
          Logger.info("Countries downloaded")
          {:ok, body}
        else
          Logger.error("Failed to download countries: #{inspect(resp)}")
          {:error, "HTTP error: #{resp.status}"}
        end

      {:error, reason} = error_tuple ->
        Logger.error("Failed to download countries: #{inspect(reason)}")
        error_tuple
    end
  end

  def fetch_features_for_country(country_code) do
    Logger.info("Downloading features for #{country_code}...")

    case Req.get("#{@base_url}/#{country_code}.zip", options()) do
      {:ok, resp} ->
        if resp.status < 400 do
          Logger.info("Features downloaded for #{country_code}")

          parse_geonames_archive(resp)
        else
          Logger.error("Failed to download features for #{country_code}: #{inspect(resp)}")
          {:error, "HTTP error: #{resp.status}"}
        end

      {:error, reason} = error_tuple ->
        Logger.error("Failed to download features for #{country_code}: #{inspect(reason)}")
        error_tuple
    end
  end

  def fetch_alternate_names_for_country(country_code) do
    Logger.info("Downloading alternate names for #{country_code}...")

    case Req.get("#{@base_url}/alternatenames/#{country_code}.zip", options()) do
      {:ok, resp} ->
        if resp.status < 400 do
          Logger.info("Alternate names downloaded for #{country_code}")

          parse_geonames_archive(resp)
        else
          Logger.error("Failed to download alternate names for #{country_code}: #{inspect(resp)}")
          {:error, "HTTP error: #{resp.status}"}
        end

      {:error, reason} = error_tuple ->
        Logger.error("Failed to download alternate names for #{country_code}: #{inspect(reason)}")
        error_tuple
    end
  end

  defp parse_geonames_archive(%Req.Response{body: [{~c"readme.txt", _}, {_, csv}]}) do
    {:ok, csv}
  end

  # suboptimal - test-only case in production code!!
  defp parse_geonames_archive(%Req.Response{body: csv}), do: {:ok, csv}

  defp options do
    Application.get_env(:hamster_travel, :geonames_req_options, [])
  end
end
