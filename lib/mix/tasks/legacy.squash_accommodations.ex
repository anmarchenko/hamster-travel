defmodule Mix.Tasks.Legacy.SquashAccommodations do
  @shortdoc "Squashes consecutive same-name accommodations into date ranges"

  @moduledoc """
  Squashes per-day legacy accommodations into contiguous ranges for each trip.

  For each trip:
  - finds consecutive accommodations with the same name
  - keeps the first, extends it to the full range
  - merges accommodation expenses to keep total unchanged
  - deletes redundant accommodations

  Prints every update/delete action before applying it.

  ## Usage

      mix legacy.squash_accommodations

  ## Options

    * `--dry-run` - Print planned changes without DB writes
  """

  use Mix.Task

  alias HamsterTravel.LegacyImport.AccommodationsSquasher

  @switches [
    dry_run: :boolean
  ]

  @impl true
  def run(args) do
    ensure_import_repo_timeouts()
    Mix.Task.run("app.start")

    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    dry_run = Keyword.get(opts, :dry_run, false)

    case AccommodationsSquasher.run(dry_run: dry_run) do
      {:ok, result} ->
        mode = if dry_run, do: "DRY-RUN", else: "APPLY"
        Mix.shell().info("Accommodation squash completed (#{mode})")
        Mix.shell().info("  trips_total: #{result.trips_total}")
        Mix.shell().info("  trips_changed: #{result.trips_changed}")
        Mix.shell().info("  groups_merged: #{result.groups_merged}")
        Mix.shell().info("  accommodations_updated: #{result.accommodations_updated}")
        Mix.shell().info("  accommodations_deleted: #{result.accommodations_deleted}")
        Mix.shell().info("  expenses_updated: #{result.expenses_updated}")
        Mix.shell().info("  expenses_deleted: #{result.expenses_deleted}")
        Mix.shell().info("  trips_failed: #{result.trips_failed}")

        if result.failures != [] do
          Mix.shell().error("Failures:")

          Enum.each(result.failures, fn failure ->
            Mix.shell().error("  #{failure.trip_id} \"#{failure.trip_name}\": #{failure.reason}")
          end)
        end
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
