defmodule HamsterTravel.LegacyImport.VisitedCitiesImporter do
  @moduledoc """
  Imports legacy user-level visited cities from CSV exports into `users_visited_cities`.
  """

  import Ecto.Query, warn: false

  alias HamsterTravel.Accounts
  alias HamsterTravel.Accounts.{User, VisitedCity}
  alias HamsterTravel.Geo.City
  alias HamsterTravel.Repo

  @type import_opts :: [
          csv_dir: String.t(),
          user_map_file: String.t(),
          limit: non_neg_integer() | nil,
          dry_run: boolean(),
          replace_existing: boolean()
        ]

  @type import_result :: %{
          total_links: non_neg_integer(),
          mapped_links: non_neg_integer(),
          distinct_pairs: non_neg_integer(),
          imported: non_neg_integer(),
          skipped_existing: non_neg_integer(),
          skipped_unmapped_user: non_neg_integer(),
          skipped_missing_legacy_city: non_neg_integer(),
          skipped_missing_geonames: non_neg_integer(),
          skipped_missing_target_city: non_neg_integer()
        }

  @spec import(import_opts()) :: {:ok, import_result()} | {:error, String.t()}
  def import(opts) do
    with {:ok, csv_dir} <- fetch_required_path(opts, :csv_dir),
         {:ok, user_map_file} <- fetch_required_path(opts, :user_map_file),
         {:ok, legacy_links} <- load_cities_users(csv_dir, opts[:limit]),
         {:ok, legacy_city_geonames} <- load_legacy_city_geonames(csv_dir),
         {:ok, legacy_user_map} <- load_user_map(user_map_file),
         {:ok, resolved_users_by_legacy_id} <- resolve_mapped_users(legacy_user_map) do
      do_import(
        legacy_links,
        legacy_city_geonames,
        resolved_users_by_legacy_id,
        dry_run: Keyword.get(opts, :dry_run, false),
        replace_existing: Keyword.get(opts, :replace_existing, false)
      )
    end
  end

  defp fetch_required_path(opts, key) do
    case Keyword.get(opts, key) do
      nil -> {:error, "missing option #{key}"}
      path when is_binary(path) -> {:ok, Path.expand(path)}
    end
  end

  defp load_cities_users(csv_dir, limit) do
    path = Path.join(csv_dir, "cities_users.csv")

    with {:ok, rows} <- read_csv_as_maps(path) do
      links =
        rows
        |> maybe_take(limit)
        |> Enum.map(fn row ->
          %{
            legacy_user_id: parse_int(row["user_id"]),
            legacy_city_id: parse_int(row["city_id"])
          }
        end)

      {:ok, links}
    end
  end

  defp load_legacy_city_geonames(csv_dir) do
    path = Path.join(csv_dir, "cities.csv")

    with {:ok, rows} <- read_csv_as_maps(path) do
      map =
        rows
        |> Enum.reduce(%{}, fn row, acc ->
          legacy_city_id = parse_int(row["id"])
          geonames_id = blank_to_nil(row["geonames_code"])

          if is_integer(legacy_city_id) do
            Map.put(acc, legacy_city_id, geonames_id)
          else
            acc
          end
        end)

      {:ok, map}
    end
  end

  defp load_user_map(path) do
    with {:ok, body} <- File.read(path),
         {:ok, parsed} <- Jason.decode(body) do
      {:ok, parsed}
    else
      {:error, :enoent} ->
        {:error, "user map file not found: #{path}"}

      {:error, reason} ->
        {:error, "failed to read user map file #{path}: #{inspect(reason)}"}
    end
  end

  defp resolve_mapped_users(legacy_user_map) when is_map(legacy_user_map) do
    Enum.reduce_while(legacy_user_map, {:ok, %{}}, fn {legacy_id, mapped}, {:ok, acc} ->
      with {legacy_user_id, ""} <- Integer.parse(to_string(legacy_id)),
           {:ok, %User{} = user} <- find_user_by_mapping_value(mapped) do
        {:cont, {:ok, Map.put(acc, legacy_user_id, user)}}
      else
        :error ->
          {:halt, {:error, "invalid legacy user id in user map: #{inspect(legacy_id)}"}}

        {:error, reason} ->
          {:halt, {:error, "cannot resolve mapped user for legacy #{legacy_id}: #{reason}"}}
      end
    end)
  end

  defp find_user_by_mapping_value(value) when is_binary(value) do
    normalized = value

    cond do
      normalized == "" ->
        {:error, "empty mapping value"}

      String.contains?(normalized, "@") ->
        case Accounts.get_user_by_email(normalized) do
          %User{} = user -> {:ok, user}
          nil -> {:error, "email not found: #{normalized}"}
        end

      true ->
        case Repo.get(User, normalized) do
          %User{} = user -> {:ok, user}
          nil -> {:error, "user id not found: #{normalized}"}
        end
    end
  end

  defp find_user_by_mapping_value(value), do: value |> to_string() |> find_user_by_mapping_value()

  defp do_import(legacy_links, legacy_city_geonames, resolved_users_by_legacy_id, opts) do
    dry_run = Keyword.get(opts, :dry_run, false)
    replace_existing = Keyword.get(opts, :replace_existing, false)

    initial = %{
      total_links: length(legacy_links),
      mapped_links: 0,
      distinct_pairs: 0,
      imported: 0,
      skipped_existing: 0,
      skipped_unmapped_user: 0,
      skipped_missing_legacy_city: 0,
      skipped_missing_geonames: 0,
      skipped_missing_target_city: 0
    }

    mapped =
      Enum.reduce(legacy_links, %{result: initial, pairs: []}, fn link, acc ->
        legacy_user_id = link.legacy_user_id
        legacy_city_id = link.legacy_city_id

        case Map.get(resolved_users_by_legacy_id, legacy_user_id) do
          nil ->
            put_in(acc.result.skipped_unmapped_user, acc.result.skipped_unmapped_user + 1)

          %User{} = user ->
            case Map.fetch(legacy_city_geonames, legacy_city_id) do
              :error ->
                put_in(
                  acc.result.skipped_missing_legacy_city,
                  acc.result.skipped_missing_legacy_city + 1
                )

              {:ok, nil} ->
                put_in(
                  acc.result.skipped_missing_geonames,
                  acc.result.skipped_missing_geonames + 1
                )

              {:ok, geonames_id} ->
                %{acc | pairs: [%{user_id: user.id, geonames_id: geonames_id} | acc.pairs]}
                |> put_in([:result, :mapped_links], acc.result.mapped_links + 1)
            end
        end
      end)

    geonames_ids =
      mapped.pairs
      |> Enum.map(& &1.geonames_id)
      |> Enum.uniq()

    city_id_by_geonames =
      from(c in City, where: c.geonames_id in ^geonames_ids, select: {c.geonames_id, c.id})
      |> Repo.all()
      |> Map.new()

    {result_with_city_resolution, resolved_pairs} =
      Enum.reduce(mapped.pairs, {mapped.result, []}, fn pair, {result, acc_pairs} ->
        case Map.get(city_id_by_geonames, pair.geonames_id) do
          nil ->
            {%{result | skipped_missing_target_city: result.skipped_missing_target_city + 1},
             acc_pairs}

          city_id ->
            {result, [%{user_id: pair.user_id, city_id: city_id} | acc_pairs]}
        end
      end)

    distinct_pairs =
      resolved_pairs
      |> Enum.uniq_by(fn pair -> {pair.user_id, pair.city_id} end)

    result = %{result_with_city_resolution | distinct_pairs: length(distinct_pairs)}

    user_ids_for_scope =
      distinct_pairs
      |> Enum.map(& &1.user_id)
      |> Enum.uniq()

    existing_pairs =
      fetch_existing_pairs(user_ids_for_scope)

    to_insert_pairs =
      if replace_existing do
        distinct_pairs
      else
        Enum.reject(distinct_pairs, fn pair ->
          MapSet.member?(existing_pairs, {pair.user_id, pair.city_id})
        end)
      end

    skipped_existing = length(distinct_pairs) - length(to_insert_pairs)

    if dry_run do
      {:ok,
       %{
         result
         | imported: length(to_insert_pairs),
           skipped_existing: skipped_existing
       }}
    else
      Repo.transaction(fn ->
        if replace_existing and user_ids_for_scope != [] do
          from(vc in VisitedCity, where: vc.user_id in ^user_ids_for_scope) |> Repo.delete_all()
        end

        timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        rows =
          Enum.map(to_insert_pairs, fn pair ->
            %{
              user_id: pair.user_id,
              city_id: pair.city_id,
              inserted_at: timestamp,
              updated_at: timestamp
            }
          end)

        {inserted_count, _} =
          Repo.insert_all(
            VisitedCity,
            rows,
            on_conflict: :nothing,
            conflict_target: [:user_id, :city_id]
          )

        %{
          result
          | imported: inserted_count,
            skipped_existing: skipped_existing
        }
      end)
      |> case do
        {:ok, summary} -> {:ok, summary}
        {:error, reason} -> {:error, "failed to import visited cities: #{format_error(reason)}"}
      end
    end
  end

  defp fetch_existing_pairs([]), do: MapSet.new()

  defp fetch_existing_pairs(user_ids) do
    from(vc in VisitedCity,
      where: vc.user_id in ^user_ids,
      select: {vc.user_id, vc.city_id}
    )
    |> Repo.all()
    |> MapSet.new()
  end

  defp maybe_take(rows, nil), do: rows

  defp maybe_take(rows, limit) when is_integer(limit) and limit >= 0,
    do: Enum.take(rows, limit)

  defp read_csv_as_maps(path) do
    with true <- File.exists?(path) do
      lines =
        path
        |> File.stream!()
        |> Stream.map(&String.trim_trailing(&1, "\n"))
        |> Stream.map(&String.trim_trailing(&1, "\r"))
        |> Stream.reject(&(&1 == ""))
        |> Enum.to_list()

      case lines do
        [header_line | data_lines] ->
          header = parse_csv_line_simple(header_line)

          rows =
            Enum.map(data_lines, fn line ->
              values = parse_csv_line_simple(line)
              Enum.zip(header, values) |> Map.new()
            end)

          {:ok, rows}

        [] ->
          {:error, "CSV file is empty: #{path}"}
      end
    else
      false -> {:error, "CSV file not found: #{path}"}
    end
  end

  defp parse_csv_line_simple(line), do: String.split(line, ",")

  defp parse_int(nil), do: nil

  defp parse_int(value) when is_integer(value), do: value

  defp parse_int(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        nil

      s ->
        case Integer.parse(s) do
          {int, ""} -> int
          _ -> nil
        end
    end
  end

  defp parse_int(_), do: nil

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(value), do: to_string(value) |> blank_to_nil()

  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error(reason), do: inspect(reason)
end
