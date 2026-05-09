defmodule Mix.Tasks.Legacy.ImportVisitedCities do
  @shortdoc "Imports legacy user-level visited cities from CSV exports"

  @moduledoc """
  Imports legacy visited cities from `cities_users.csv` into `users_visited_cities`.

  ## Usage

      mix legacy.import_visited_cities --csv-dir prod_backup/legacy_csv_clean --user-map-file path/to/user_map.json

  ## Options

    * `--csv-dir` - Directory with legacy CSV files (default: `prod_backup/legacy_csv_clean`)
    * `--user-map-file` - JSON mapping of legacy user ids to target users (required)
    * `--limit` - Process only first N rows from `cities_users.csv`
    * `--dry-run` - Read/resolve everything, print summary, no DB writes
    * `--replace-existing` - Replace existing visited cities for mapped users

  `--user-map-file` expects JSON like:

      {
        "191": "author@example.com",
        "192": "participant@example.com"
      }
  """

  use Mix.Task

  alias HamsterTravel.LegacyImport.VisitedCitiesImporter

  @switches [
    csv_dir: :string,
    user_map_file: :string,
    limit: :integer,
    dry_run: :boolean,
    replace_existing: :boolean
  ]

  @impl true
  def run(args) do
    ensure_import_repo_timeouts()
    Mix.Task.run("app.start")

    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    csv_dir = Keyword.get(opts, :csv_dir, "prod_backup/legacy_csv_clean")
    user_map_file = Keyword.get(opts, :user_map_file)

    if is_nil(user_map_file) do
      Mix.raise("--user-map-file is required")
    end

    import_opts = [
      csv_dir: csv_dir,
      user_map_file: user_map_file,
      limit: Keyword.get(opts, :limit),
      dry_run: Keyword.get(opts, :dry_run, false),
      replace_existing: Keyword.get(opts, :replace_existing, false)
    ]

    case VisitedCitiesImporter.import(import_opts) do
      {:ok, result} ->
        Mix.shell().info("Legacy visited cities import completed")
        Mix.shell().info("  total_links: #{result.total_links}")
        Mix.shell().info("  mapped_links: #{result.mapped_links}")
        Mix.shell().info("  distinct_pairs: #{result.distinct_pairs}")
        Mix.shell().info("  imported: #{result.imported}")
        Mix.shell().info("  skipped_existing: #{result.skipped_existing}")
        Mix.shell().info("  skipped_unmapped_user: #{result.skipped_unmapped_user}")
        Mix.shell().info("  skipped_missing_legacy_city: #{result.skipped_missing_legacy_city}")
        Mix.shell().info("  skipped_missing_geonames: #{result.skipped_missing_geonames}")
        Mix.shell().info("  skipped_missing_target_city: #{result.skipped_missing_target_city}")

      {:error, reason} ->
        Mix.raise("Legacy visited cities import failed: #{reason}")
    end
  end

  defp ensure_import_repo_timeouts do
    System.put_env(
      "LEGACY_IMPORT_DB_TIMEOUT_MS",
      System.get_env("LEGACY_IMPORT_DB_TIMEOUT_MS") || "600000"
    )

    System.put_env(
      "LEGACY_IMPORT_DB_POOL_TIMEOUT_MS",
      System.get_env("LEGACY_IMPORT_DB_POOL_TIMEOUT_MS") || "600000"
    )
  end
end
