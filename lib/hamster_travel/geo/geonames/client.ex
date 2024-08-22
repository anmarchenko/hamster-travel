defmodule HamsterTravel.Geo.Geonames.Client do
  @base_url "https://download.geonames.org/export/dump"

  require Logger

  def fetch_countries do
    Logger.info("Downloading countries...")

    case Req.get("#{@base_url}/countryInfo.txt", options()) do
      {:ok, %Req.Response{body: body} = resp} ->
        if resp.status < 400 do
          {:ok, body}
        else
          :telemetry.execute(
            [:hamster_travel, :geonames, :fetch_countries],
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
          [:hamster_travel, :geonames, :fetch_countries],
          %{error: 1},
          %{
            reason: "network"
          }
        )

        Logger.error("Failed to download countries: #{inspect(reason)}")
        error_tuple
    end
  end

  def fetch_features_for_country(iso_code) do
    Logger.info("Downloading features for #{iso_code}...")

    case Req.get("#{@base_url}/#{iso_code}.zip", options()) do
      {:ok, resp} ->
        if resp.status < 400 do
          parse_features_response(resp)
        else
          :telemetry.execute(
            [:hamster_travel, :geonames, :fetch_features],
            %{error: 1},
            %{
              reason: "status_#{resp.status}"
            }
          )

          Logger.error("Failed to download features for #{iso_code}: #{inspect(resp)}")
          {:error, "HTTP error: #{resp.status}"}
        end

      {:error, reason} = error_tuple ->
        :telemetry.execute(
          [:hamster_travel, :geonames, :fetch_features],
          %{error: 1},
          %{
            reason: "network"
          }
        )

        Logger.error("Failed to download features for #{iso_code}: #{inspect(reason)}")
        error_tuple
    end
  end

  defp parse_features_response(%Req.Response{body: [{~c"readme.txt", _}, {_, csv}]}) do
    {:ok, csv}
  end

  # suboptimal - test-only case in production code!!
  defp parse_features_response(%Req.Response{body: csv}), do: {:ok, csv}

  defp options do
    Application.get_env(:hamster_travel, :geonames_req_options, [])
  end
end
