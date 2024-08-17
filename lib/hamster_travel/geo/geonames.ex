defmodule HamsterTravel.Geo.Geonames do
  @moduledoc """
  Handles downloading, parsing, and importing geonames data.
  """
  alias HamsterTravel.Geo
  alias HamsterTravel.Geo.Country
  alias HamsterTravel.Repo

  require Logger

  def import do
    Logger.info("Importing geonames data...")
    import_countries()

    iso_codes = Geo.list_country_iso_codes()

    iso_codes
    |> Enum.each(&import_features/1)
  end

  def import_features(iso_code) do
    {:ok, features} = download_features(iso_code)

    features =
      features
      |> String.split("\n")
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.map(&String.split(String.trim(&1), "\t"))
      # |> Enum.map(&parse_feature/1)
      |> Enum.reject(fn feature_data ->
        feature_data == nil
      end)

    {entries_count, _} =
      Repo.insert_all(
        Geo.Region,
        features,
        on_conflict: {:replace_all_except, [:id, :inserted_at, :name_ru]},
        conflict_target: :geonames_id
      )

    Logger.info("Imported #{entries_count} features for #{iso_code}")
  end

  def import_countries do
    {:ok, countries} = download_countries()

    countries =
      countries
      |> String.split("\n")
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.map(&String.split(String.trim(&1), "\t"))
      |> Enum.map(&parse_country/1)
      |> Enum.reject(fn country_data ->
        country_data == nil || country_data[:iso] == "CS" || country_data[:iso] == "AN"
      end)

    {entries_count, _} =
      Repo.insert_all(
        Country,
        countries,
        on_conflict: {:replace_all_except, [:id, :inserted_at, :name_ru]},
        conflict_target: :geonames_id
      )

    Logger.info("Imported #{entries_count} countries")
  end

  defp download_countries do
    case Req.get("https://download.geonames.org/export/dump/countryInfo.txt", options()) do
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

  defp download_features(iso_code) do
    case Req.get("https://download.geonames.org/export/dump/#{iso_code}.zip", options()) do
      {:ok, %Req.Response{body: [{_, _}, {_, csv}]} = resp} ->
        if resp.status < 400 do
          {:ok, csv}
        else
          :telemetry.execute(
            [:hamster_travel, :geonames, :download_features],
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
          [:hamster_travel, :geonames, :download_features],
          %{error: 1},
          %{
            reason: "network"
          }
        )

        Logger.error("Failed to download features for #{iso_code}: #{inspect(reason)}")
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
    population = String.to_integer(population)

    if population <= 0 do
      nil
    else
      %{
        geonames_id: geonames_id,
        iso: iso,
        iso3: iso3,
        ison: ison,
        name: name,
        continent: continent,
        currency_code: currency_code,
        currency_name: currency_name,
        inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
        updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      }
    end
  end

  defp parse_country(_) do
    nil
  end

  defp options do
    Application.get_env(:hamster_travel, :geonames_req_options, [])
  end
end
