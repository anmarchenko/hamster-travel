defmodule HamsterTravel.Geo.Geonames.Translations do
  require Logger

  alias HamsterTravel.Geo.Geonames.Client

  def fetch(country_code) do
    Logger.info("Fetching translations for #{country_code}...")

    case Client.fetch_alternate_names_for_country(country_code) do
      {:ok, alternative_names} ->
        translations =
          alternative_names
          |> String.split("\n")
          |> Enum.map(&String.split(&1, "\t"))
          |> Enum.map(&parse_translation/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.reduce(%{}, &store_translation/2)

        {:ok, translations}

      _ ->
        {:error, :network}
    end
  end

  defp parse_translation([
         _,
         geonames_id,
         lang,
         altname,
         is_preferred,
         is_short,
         is_colloquial,
         is_historic,
         _,
         _
       ]) do
    if lang != "ru" || is_short == "1" || is_colloquial == "1" || is_historic == "1" do
      nil
    else
      %{geonames_id: geonames_id, name_ru: altname, preferred: is_preferred == "1"}
    end
  end

  defp parse_translation(_), do: nil

  def store_translation(translation, acc) do
    Map.update(acc, translation.geonames_id, translation.name_ru, fn existing ->
      if translation.preferred do
        translation.name_ru
      else
        existing
      end
    end)
  end
end
