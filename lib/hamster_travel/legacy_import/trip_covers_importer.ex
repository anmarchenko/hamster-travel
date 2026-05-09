defmodule HamsterTravel.LegacyImport.TripCoversImporter do
  @moduledoc """
  Imports trip covers from legacy public URLs into current trip cover storage.
  """

  import Ecto.Query, warn: false
  require Logger

  alias HamsterTravel.Accounts
  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{Trip, TripCover}
  alias HamsterTravel.Repo

  @default_cover_base_url "https://d2fetf4i8a4kn6.cloudfront.net/"
  @default_timeout_ms 120_000

  @type import_opts :: [
          bundle_dir: String.t(),
          user_map_file: String.t(),
          limit: non_neg_integer() | nil,
          overwrite: boolean(),
          continue_on_error: boolean(),
          dry_run: boolean(),
          cover_base_url: String.t() | nil,
          request_timeout_ms: pos_integer(),
          report_file: String.t() | nil
        ]

  @type import_result :: %{
          total: non_neg_integer(),
          with_cover: non_neg_integer(),
          updated: non_neg_integer(),
          skipped_no_cover: non_neg_integer(),
          skipped_existing_cover: non_neg_integer(),
          skipped_no_trip_match: non_neg_integer(),
          failed: non_neg_integer(),
          failures: list(%{trip_ref: String.t() | nil, reason: String.t()})
        }

  @spec import(import_opts()) :: {:ok, import_result()} | {:error, String.t()}
  def import(opts) do
    with {:ok, bundle_dir} <- fetch_required_path(opts, :bundle_dir),
         {:ok, user_map_file} <- fetch_required_path(opts, :user_map_file),
         {:ok, bundles} <- load_trip_bundles(bundle_dir, opts[:limit]),
         {:ok, legacy_user_ids} <- collect_legacy_user_ids(bundles),
         {:ok, legacy_user_map} <- load_user_map(user_map_file),
         {:ok, resolved_users} <- resolve_users(legacy_user_ids, legacy_user_map),
         {:ok, result} <- do_import(bundles, resolved_users, opts) do
      maybe_write_report(result, opts[:report_file])
      {:ok, result}
    end
  end

  defp fetch_required_path(opts, key) do
    case Keyword.get(opts, key) do
      nil -> {:error, "missing option #{key}"}
      path when is_binary(path) -> {:ok, Path.expand(path)}
    end
  end

  defp load_trip_bundles(bundle_dir, limit) do
    path = Path.join(bundle_dir, "trips.jsonl")

    if File.exists?(path) do
      bundles =
        path
        |> File.stream!()
        |> Stream.reject(&String.match?(&1, ~r/^\s*$/u))
        |> Stream.map(&Jason.decode!/1)
        |> maybe_take(limit)
        |> Enum.to_list()

      {:ok, bundles}
    else
      {:error, "trips.jsonl not found at #{path}"}
    end
  end

  defp maybe_take(stream, nil), do: stream

  defp maybe_take(stream, limit) when is_integer(limit) and limit >= 0,
    do: Stream.take(stream, limit)

  defp collect_legacy_user_ids(bundles) do
    legacy_user_ids =
      bundles
      |> Enum.map(& &1["author_legacy_user_id"])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    {:ok, legacy_user_ids}
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

  defp resolve_users(legacy_user_ids, legacy_user_map) do
    Enum.reduce_while(legacy_user_ids, {:ok, %{}}, fn legacy_id, {:ok, acc} ->
      key = to_string(legacy_id)

      case Map.fetch(legacy_user_map, key) do
        :error ->
          {:halt, {:error, "missing user mapping for legacy user #{key}"}}

        {:ok, nil} ->
          {:halt, {:error, "mapping for legacy user #{key} is null"}}

        {:ok, mapped} ->
          case find_user_by_mapping_value(mapped) do
            {:ok, %User{} = user} ->
              {:cont, {:ok, Map.put(acc, legacy_id, user)}}

            {:error, reason} ->
              {:halt, {:error, "cannot resolve mapped user for legacy #{key}: #{reason}"}}
          end
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

  defp do_import(bundles, resolved_users, opts) do
    overwrite = Keyword.get(opts, :overwrite, false)
    continue_on_error = Keyword.get(opts, :continue_on_error, false)
    dry_run = Keyword.get(opts, :dry_run, false)
    timeout_ms = Keyword.get(opts, :request_timeout_ms, @default_timeout_ms)
    cover_base_url = Keyword.get(opts, :cover_base_url, @default_cover_base_url)

    initial = %{
      total: length(bundles),
      with_cover: 0,
      updated: 0,
      skipped_no_cover: 0,
      skipped_existing_cover: 0,
      skipped_no_trip_match: 0,
      failed: 0,
      failures: []
    }

    result =
      Enum.reduce_while(bundles, initial, fn bundle, acc ->
        case process_bundle(
               bundle,
               resolved_users,
               cover_base_url,
               overwrite,
               dry_run,
               timeout_ms
             ) do
          {:ok, :no_cover} ->
            {:cont, %{acc | skipped_no_cover: acc.skipped_no_cover + 1}}

          {:ok, :existing_cover} ->
            {:cont,
             %{
               acc
               | with_cover: acc.with_cover + 1,
                 skipped_existing_cover: acc.skipped_existing_cover + 1
             }}

          {:ok, :uploaded} ->
            {:cont, %{acc | with_cover: acc.with_cover + 1, updated: acc.updated + 1}}

          {:ok, :dry_run} ->
            {:cont, %{acc | with_cover: acc.with_cover + 1, updated: acc.updated + 1}}

          {:error, :no_trip_match, reason} ->
            failures = [%{trip_ref: bundle["trip_ref"], reason: reason} | acc.failures]

            next = %{
              acc
              | with_cover: acc.with_cover + 1,
                skipped_no_trip_match: acc.skipped_no_trip_match + 1,
                failed: acc.failed + 1,
                failures: failures
            }

            if continue_on_error, do: {:cont, next}, else: {:halt, next}

          {:error, reason} ->
            failures = [%{trip_ref: bundle["trip_ref"], reason: reason} | acc.failures]

            next = %{
              acc
              | with_cover: acc.with_cover + 1,
                failed: acc.failed + 1,
                failures: failures
            }

            if continue_on_error, do: {:cont, next}, else: {:halt, next}
        end
      end)

    {:ok, %{result | failures: Enum.reverse(result.failures)}}
  end

  defp process_bundle(bundle, resolved_users, cover_base_url, overwrite, dry_run, timeout_ms) do
    cover_url = cover_url(bundle, cover_base_url)

    if is_nil(cover_url) do
      {:ok, :no_cover}
    else
      with {:ok, author} <- fetch_author(bundle, resolved_users),
           {:ok, trip} <- find_target_trip(bundle, author),
           :ok <- maybe_skip_existing_cover(trip, overwrite),
           {:ok, upload} <- download_cover_upload(cover_url, timeout_ms) do
        result = store_cover(trip, upload, dry_run)
        cleanup_temp_upload(upload)
        maybe_log_cover_result(result, bundle, trip, cover_url)
        result
      else
        {:skip, :existing_cover} ->
          {:ok, :existing_cover}

        {:error, :no_trip_match, reason} ->
          {:error, :no_trip_match, reason}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp cover_url(bundle, cover_base_url) do
    direct = blank_to_nil(bundle["legacy_cover_url"])

    cond do
      direct ->
        direct

      uid = blank_to_nil(bundle["legacy_image_uid"]) ->
        "#{String.trim_trailing(cover_base_url || @default_cover_base_url, "/")}/#{uid}"

      true ->
        nil
    end
  end

  defp fetch_author(%{"author_legacy_user_id" => legacy_author_id}, resolved_users) do
    case Map.fetch(resolved_users, legacy_author_id) do
      {:ok, user} -> {:ok, user}
      :error -> {:error, "author mapping missing for legacy user #{legacy_author_id}"}
    end
  end

  defp find_target_trip(bundle, %User{} = author) do
    status = bundle["status"]
    name = bundle["name"]
    dates_unknown = bundle["dates_unknown"] || false
    duration = bundle["duration"]
    start_date = parse_date(bundle["start_date"])
    end_date = parse_date(bundle["end_date"])
    currency = bundle["currency"]
    people_count = bundle["people_count"]

    matches =
      from(t in Trip,
        where:
          t.author_id == ^author.id and
            t.name == ^name and
            t.status == ^status and
            t.dates_unknown == ^dates_unknown and
            t.duration == ^duration and
            t.start_date == ^start_date and
            t.end_date == ^end_date and
            t.currency == ^currency and
            t.people_count == ^people_count
      )
      |> Repo.all()

    case matches do
      [trip] ->
        {:ok, trip}

      [] ->
        {:error, :no_trip_match, "trip not found by author/name/date/status match"}

      trips ->
        ids = Enum.map_join(trips, ",", & &1.id)
        {:error, :no_trip_match, "multiple trip matches found: #{ids}"}
    end
  end

  defp maybe_skip_existing_cover(%Trip{} = _trip, true), do: :ok

  defp maybe_skip_existing_cover(%Trip{} = trip, false) do
    if TripCover.present?(trip.cover) do
      {:skip, :existing_cover}
    else
      :ok
    end
  end

  defp download_cover_upload(url, timeout_ms) do
    response =
      Req.get(url,
        decode_body: false,
        receive_timeout: timeout_ms,
        connect_options: [timeout: min(timeout_ms, 60_000)],
        retry: :transient,
        max_retries: 2
      )

    with {:ok, resp} <- response,
         200 <- resp.status do
      content_type = response_content_type(resp, url)
      filename = url_filename(url)
      extension = Path.extname(filename)
      safe_extension = if extension == "", do: ".bin", else: extension

      tmp_path =
        Path.join(
          System.tmp_dir!(),
          "legacy-trip-cover-#{System.unique_integer([:positive])}#{safe_extension}"
        )

      :ok = File.write(tmp_path, resp.body)

      {:ok,
       %Plug.Upload{
         path: tmp_path,
         filename: filename,
         content_type: content_type
       }}
    else
      {:ok, resp} ->
        {:error, "failed to download cover #{url}: status #{resp.status}"}

      {:error, reason} ->
        {:error, "failed to download cover #{url}: #{Exception.message(reason)}"}
    end
  end

  defp store_cover(_trip, upload, true) do
    _ = upload
    {:ok, :dry_run}
  end

  defp store_cover(%Trip{} = trip, upload, false) do
    case Planning.update_trip_cover(trip, upload) do
      {:ok, _updated_trip} ->
        {:ok, :uploaded}

      {:error, changeset} ->
        {:error, "failed to store cover: #{inspect(changeset.errors)}"}
    end
  end

  defp maybe_log_cover_result({:ok, status}, bundle, %Trip{} = trip, cover_url)
       when status in [:uploaded, :dry_run] do
    trip_ref = bundle["trip_ref"] || "unknown"
    trip_name = trip.name || "unknown"

    Logger.info(
      "Legacy cover #{status}: trip_ref=#{trip_ref} trip_id=#{trip.id} trip_name=#{inspect(trip_name)} original_url=#{cover_url}"
    )

    :ok
  end

  defp maybe_log_cover_result(_result, _bundle, _trip, _cover_url), do: :ok

  defp cleanup_temp_upload(%Plug.Upload{path: path}) when is_binary(path) do
    _ = File.rm(path)
    :ok
  end

  defp cleanup_temp_upload(_), do: :ok

  defp response_content_type(resp, url) do
    case Req.Response.get_header(resp, "content-type") do
      [value | _] ->
        value
        |> String.split(";", parts: 2)
        |> hd()
        |> String.trim()

      [] ->
        MIME.from_path(url_filename(url))
    end
  end

  defp url_filename(url) do
    case URI.parse(url) do
      %URI{path: path} when is_binary(path) and path != "" ->
        Path.basename(path)

      _ ->
        "cover.jpg"
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(_), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(_), do: nil

  defp maybe_write_report(_result, nil), do: :ok

  defp maybe_write_report(result, path) when is_binary(path) do
    report_path = Path.expand(path)
    _ = File.mkdir_p(Path.dirname(report_path))
    File.write!(report_path, Jason.encode_to_iodata!(result, pretty: true))
  end
end
