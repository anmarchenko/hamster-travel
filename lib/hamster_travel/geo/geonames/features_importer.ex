defmodule HamsterTravel.Geo.Geonames.FeaturesImporter do
  alias HamsterTravel.Geo.{City, Region}
  alias HamsterTravel.Repo

  defmodule FeaturesImportData do
    defstruct regions: [], cities: [], valid_region_codes: %{}
  end

  require Logger

  def process(features, country_code) do
    Logger.info("Importing features for #{country_code}...")

    features =
      features
      |> String.split("\n")
      |> Enum.map(&String.split(String.trim(&1), "\t"))

    # we have to do 2 passes on features list because we must know in advance
    # which region codes are valid for the given country
    # geonames data has broken region codes that violate foreign key constraints
    valid_region_codes = collect_valid_region_codes(features)

    # now we parse features
    features =
      features
      |> Enum.reduce(
        %FeaturesImportData{regions: [], cities: [], valid_region_codes: valid_region_codes},
        &parse_feature/2
      )

    {regions_count, _} =
      Repo.insert_all(
        Region,
        features.regions,
        on_conflict: {:replace_all_except, [:id, :inserted_at, :name_ru]},
        conflict_target: :geonames_id
      )

    Logger.info("Imported #{regions_count} regions for #{country_code}")

    cities_count =
      features.cities
      # insert data in chunks as cities count might exceed postgres parameter limit
      |> Enum.chunk_every(3000)
      |> Enum.reduce(0, fn chunk, overall_count ->
        {cities_count, _} =
          Repo.insert_all(
            City,
            chunk,
            on_conflict: {:replace_all_except, [:id, :inserted_at, :name_ru]},
            conflict_target: :geonames_id
          )

        cities_count + overall_count
      end)

    Logger.info("Imported #{cities_count} cities for #{country_code}")
  end

  defp parse_feature(
         [
           geoname_id,
           name,
           _,
           _,
           lat,
           lon,
           feature_class,
           feature_code,
           country_code,
           _,
           admin1_code,
           _,
           _,
           _,
           population,
           _,
           _,
           _,
           _
         ],
         %FeaturesImportData{} = import_data
       ) do
    admin1_code = nilify_invalid_region_code(admin1_code, import_data.valid_region_codes)

    {lat, _} = Float.parse(lat)
    {lon, _} = Float.parse(lon)

    geo_map = %{
      name: name,
      country_code: country_code,
      region_code: admin1_code,
      geonames_id: geoname_id,
      lat: lat,
      lon: lon,
      inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
      updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    }

    case {feature_class, feature_code} do
      {"A", "ADM1"} ->
        Map.replace(import_data, :regions, [geo_map | import_data.regions])

      {"P", _} ->
        population = String.to_integer(population)

        if population >= 5 do
          geo_map = Map.put(geo_map, :population, population)
          Map.replace(import_data, :cities, [geo_map | import_data.cities])
        else
          import_data
        end

      {_, _} ->
        import_data
    end
  end

  defp parse_feature(_, import_data) do
    import_data
  end

  defp collect_valid_region_codes(features) do
    features
    |> Enum.reduce(%{}, fn arr, acc ->
      region_code = Enum.at(arr, 10)

      feature_class = Enum.at(arr, 6)
      feature_code = Enum.at(arr, 7)

      if feature_class == "A" && feature_code == "ADM1" do
        Map.put(acc, region_code, true)
      else
        acc
      end
    end)
  end

  defp nilify_invalid_region_code(region_code, valid_region_codes) do
    if Map.get(valid_region_codes, region_code) do
      region_code
    else
      nil
    end
  end
end
