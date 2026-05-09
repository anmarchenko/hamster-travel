defmodule Mix.Tasks.Legacy.ImportExternalParticipantTrips do
  @shortdoc "Imports omitted legacy trips with filtered participants (191/192 only)"

  @moduledoc """
  Imports the supplemental legacy bundle that contains trips previously omitted by
  old cleanup logic (trips connected to users outside 191/192).

  This task does NOT purge existing trips and appends only bundles from the given
  supplemental directory.

  ## Usage

      mix legacy.import_external_participant_trips --user-map-file path/to/user_map.json

  ## Options

    * `--bundle-dir` - Directory with `trips.jsonl` (default: `prod_backup/import_ready_external_participants`)
    * `--user-map-file` - JSON mapping of legacy user ids to target users (required)
    * `--limit` - Import only first N trip bundles
    * `--skip-missing-cities` - Skip destinations/transfers whose geonames city is not found
    * `--continue-on-error` - Continue processing next trips when a trip import fails
  """

  use Mix.Task

  alias HamsterTravel.LegacyImport.TripsImporter

  @switches [
    bundle_dir: :string,
    user_map_file: :string,
    limit: :integer,
    skip_missing_cities: :boolean,
    continue_on_error: :boolean
  ]

  @impl true
  def run(args) do
    ensure_import_repo_timeouts()
    Mix.Task.run("app.start")

    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    bundle_dir = Keyword.get(opts, :bundle_dir, "prod_backup/import_ready_external_participants")
    user_map_file = Keyword.get(opts, :user_map_file)

    if is_nil(user_map_file) do
      Mix.raise("--user-map-file is required")
    end

    import_opts = [
      bundle_dir: bundle_dir,
      user_map_file: user_map_file,
      limit: Keyword.get(opts, :limit),
      skip_missing_cities: Keyword.get(opts, :skip_missing_cities, false),
      continue_on_error: Keyword.get(opts, :continue_on_error, false),
      purge_existing: false
    ]

    case TripsImporter.import(import_opts) do
      {:ok, result} ->
        Mix.shell().info("Supplemental legacy import completed")
        Mix.shell().info("  total: #{result.total}")
        Mix.shell().info("  imported: #{result.imported}")
        Mix.shell().info("  failed: #{result.failed}")

        if result.failures != [] do
          Mix.shell().error("Failures:")

          Enum.each(result.failures, fn failure ->
            Mix.shell().error("  #{failure.trip_ref}: #{failure.reason}")
          end)
        end

      {:error, reason} ->
        Mix.raise("Supplemental legacy import failed: #{reason}")
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
