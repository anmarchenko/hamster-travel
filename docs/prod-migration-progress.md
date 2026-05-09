# Production Migration Progress

## 2026-05-09 (supplemental import for trips omitted by external participants)

### Goal
Recover trips that were wrongly excluded by cleanup logic when they had at least one participant outside legacy users `191/192`.

### Completed
- Built full legacy conversion bundle from uncleaned export:
  - input: `prod_backup/legacy_csv`
  - output: `prod_backup/import_ready_full`
- Added reusable supplemental-bundle builder:
  - [`scripts/build_external_participant_supplemental_bundle.py`](/Users/marvin/p/hamster-travel/scripts/build_external_participant_supplemental_bundle.py)
  - selects trips absent from baseline bundle but authored by kept users and linked to external participants
  - rewrites participants to keep only `191/192`
  - outputs:
    - `prod_backup/import_ready_external_participants/trips.jsonl`
    - `prod_backup/import_ready_external_participants/summary.json`
    - `prod_backup/import_ready_external_participants/omitted_trips.md`
- Extended shared trip importer to support append mode:
  - [`lib/hamster_travel/legacy_import/trips_importer.ex`](/Users/marvin/p/hamster-travel/lib/hamster_travel/legacy_import/trips_importer.ex)
  - new option `purge_existing` (default `true`)
- Added dedicated append-only mix task:
  - [`lib/mix/tasks/legacy.import_external_participant_trips.ex`](/Users/marvin/p/hamster-travel/lib/mix/tasks/legacy.import_external_participant_trips.ex)
  - always uses `purge_existing: false` (does not delete existing trips)
- Updated documentation:
  - [`docs/legacy-import-format.md`](/Users/marvin/p/hamster-travel/docs/legacy-import-format.md)

### Local Validation
- Supplemental bundle selected `4` trips.
- Local append-only import run:
  - `mix legacy.import_external_participant_trips --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --continue-on-error`
  - result: `total=4`, `imported=4`, `failed=0`
- Trips table count:
  - before: `98`
  - after: `102`

## 2026-05-09 (visited cities separate importer)

### Goal
Migrate legacy user-level visited cities (not tied to trips) independently from trip import.

### Completed
- Added importer module: [`lib/hamster_travel/legacy_import/visited_cities_importer.ex`](/Users/marvin/p/hamster-travel/lib/hamster_travel/legacy_import/visited_cities_importer.ex)
  - reads legacy `cities_users.csv` and `cities.csv`
  - resolves legacy users via existing mapping JSON
  - maps legacy city IDs to new city IDs via geonames code
  - inserts into `users_visited_cities` with dedup protection (`on_conflict: :nothing`)
  - supports `--dry-run`, `--replace-existing`, and `--limit`.
- Added task: [`lib/mix/tasks/legacy.import_visited_cities.ex`](/Users/marvin/p/hamster-travel/lib/mix/tasks/legacy.import_visited_cities.ex)
  - command: `mix legacy.import_visited_cities`.
- Updated format doc:
  - [`docs/legacy-import-format.md`](/Users/marvin/p/hamster-travel/docs/legacy-import-format.md).

## 2026-05-09 (cover import per-trip logging)

### Goal
Improve observability during cover migration by logging each successfully processed trip cover with source URL.

### Completed
- Updated [`lib/hamster_travel/legacy_import/trip_covers_importer.ex`](/Users/marvin/p/hamster-travel/lib/hamster_travel/legacy_import/trip_covers_importer.ex):
  - Logs a line for each successful `:uploaded` and `:dry_run` result.
  - Log includes: `trip_ref`, target `trip_id`, `trip_name`, and `original_url` (legacy cover URL).

## 2026-05-09 (legacy trip covers import automation)

### Goal
Automate migration of legacy trip cover images from old public CloudFront URLs into new trip cover storage for already imported trips.

### Completed
- Updated converter output in [`scripts/convert_legacy_csv_for_import.py`](/Users/marvin/p/hamster-travel/scripts/convert_legacy_csv_for_import.py):
  - adds `legacy_image_uid` and `legacy_cover_url` per trip bundle.
  - cover URL format: `https://d2fetf4i8a4kn6.cloudfront.net/<image_uid>`.
- Added cover importer module: [`lib/hamster_travel/legacy_import/trip_covers_importer.ex`](/Users/marvin/p/hamster-travel/lib/hamster_travel/legacy_import/trip_covers_importer.ex)
  - resolves target trip by imported bundle attributes + mapped author
  - downloads legacy image via HTTP
  - stores cover through `Planning.update_trip_cover/2` (Waffle pipeline, same as app upload flow)
  - supports `--overwrite`, `--dry-run`, `--continue-on-error`, report output.
- Added mix task: [`lib/mix/tasks/legacy.import_trip_covers.ex`](/Users/marvin/p/hamster-travel/lib/mix/tasks/legacy.import_trip_covers.ex)
  - command: `mix legacy.import_trip_covers`.
- Updated import format documentation with cover fields and command:
  - [`docs/legacy-import-format.md`](/Users/marvin/p/hamster-travel/docs/legacy-import-format.md).

### Validation
- CloudFront URL generation/reachability from current legacy dataset:
  - `trips.image_uid` non-empty rows: `113`
  - URL checks: `113/113` returned HTTP 200.
- Dry-run task check against local imported DB:
  - `mix legacy.import_trip_covers --bundle-dir prod_backup/import_ready --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --limit 5 --dry-run --continue-on-error`
  - Result: `total=5`, `with_cover=5`, `updated=5`, `failed=0`.

## 2026-05-09 (temporary import timeout override for prod proxy runs)

### Goal
Prevent legacy import failures over Fly DB proxy caused by default 15s Ecto checkout/query timeout.

### Completed
- Updated [`config/runtime.exs`](/Users/marvin/p/hamster-travel/config/runtime.exs) (prod Repo config):
  - `timeout` now reads `LEGACY_IMPORT_DB_TIMEOUT_MS` (default `15000`)
  - `pool_timeout` now reads `LEGACY_IMPORT_DB_POOL_TIMEOUT_MS` (default `15000`)
- Updated [`lib/mix/tasks/legacy.import_trips.ex`](/Users/marvin/p/hamster-travel/lib/mix/tasks/legacy.import_trips.ex):
  - before app start, task now sets defaults when unset:
    - `LEGACY_IMPORT_DB_TIMEOUT_MS=600000`
    - `LEGACY_IMPORT_DB_POOL_TIMEOUT_MS=600000`
- This keeps normal prod behavior unchanged unless running the import task (or explicitly setting the env vars).

## 2026-05-09 (drop placeholder legacy accommodations)

### Goal
Do not import placeholder accommodations named `Legacy accommodation` that carry no useful data.

### Completed
- Updated converter logic in [`scripts/convert_legacy_csv_for_import.py`](/Users/marvin/p/hamster-travel/scripts/convert_legacy_csv_for_import.py):
  - skip legacy hotel rows when name is `Legacy accommodation` (case-insensitive) and row has no link, note, or expense
  - also skip fully empty hotel rows
  - for non-empty rows without a name, use fallback title `Accommodation`
- Re-generated import bundle:
  - `UV_CACHE_DIR=.uv-cache uv run python scripts/convert_legacy_csv_for_import.py`
- Re-imported local dev DB:
  - `MIX_BUILD_PATH=_build_codex mix legacy.import_trips --bundle-dir prod_backup/import_ready --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --continue-on-error`

### Validation
- Converted bundle contains `0` accommodations named `Legacy accommodation`.
- DB check after import:
  - `SELECT count(*) FROM accommodations WHERE name ILIKE 'legacy accommodation'` -> `0`
- Import result:
  - `total: 98`
  - `imported: 98`
  - `failed: 0`

## 2026-05-09 (draft visibility policy)

### Goal
Show wife-authored drafts in the new app drafts list for friends (same as imported dataset expectation).

### Completed
- Updated draft visibility policy in [`lib/hamster_travel/planning/policy.ex`](/Users/marvin/p/hamster-travel/lib/hamster_travel/planning/policy.ex):
  - `user_drafts_scope/2` now includes drafts where `author_id` is in the user's friends circle (not only own drafts / participant drafts).
- Added unit coverage in [`test/hamster_travel/planning/policy_test.exs`](/Users/marvin/p/hamster-travel/test/hamster_travel/planning/policy_test.exs):
  - new test for friend-authored draft visibility.
- Updated planning behavior assertion in [`test/hamster_travel/planning_test.exs`](/Users/marvin/p/hamster-travel/test/hamster_travel/planning_test.exs):
  - `list_drafts/1` now expects friend-authored drafts in results.

### Validation
- `mix test test/hamster_travel/planning/policy_test.exs test/hamster_travel/planning_test.exs`
- Result: `252 tests, 0 failures`.

## 2026-03-04

### Goal
Import the old production backup into local Postgres so we can start incremental conversion into importable files for the new Hamster Travel schema.

### Completed
- Located backup file: `prod_backup/PostgreSQL.sql` (plain SQL dump).
- Confirmed project Postgres is running at `localhost:6000`.
- Created restore database: `hamster_travel_legacy_prod`.
- Imported dump into that database with `psql`.

### Commands Run
```bash
PGPASSWORD=postgres dropdb --if-exists -h localhost -p 6000 -U postgres hamster_travel_legacy_prod
PGPASSWORD=postgres createdb -h localhost -p 6000 -U postgres hamster_travel_legacy_prod
PGPASSWORD=postgres psql -h localhost -p 6000 -U postgres -d hamster_travel_legacy_prod -f prod_backup/PostgreSQL.sql
```

### Validation
- Public tables restored: `31`
- Sample row counts:
  - `users`: `144`
  - `trips`: `166`
  - `days`: `1041`
  - `cities`: `205040`
  - `schema_migrations`: `52`

### Notes
- Restore produced non-fatal errors during initial `DROP` operations on missing objects (expected in a fresh DB).
- Restore also produced non-fatal `role "librarian" does not exist` errors for ownership/ACL statements from old production.
- Import log saved at `/tmp/hamster_travel_legacy_prod_import.log`.

### Next Step
- Inspect old schema table-by-table and define first export format (likely CSV/JSON per domain context) for importing into new Hamster Travel.

## 2026-03-04 (continued)

### Goal
Export all legacy tables to CSV and document the legacy schema for mapping to the new data model.

### Completed
- Exported CSV files for all `31` public tables from `hamster_travel_legacy_prod` to `prod_backup/legacy_csv/`.
- Added export manifest file: `prod_backup/legacy_csv/_manifest.csv`.
- Verified coverage: exported tables count equals DB table count (`31`).
- Generated schema documentation: `docs/legacy-db-schema.md`.

### Notes
- One CSV file was created per table with header row.
- Schema doc includes, for each table: row count, primary key, foreign key count/details, and all columns (type, nullability, default).

## 2026-03-08

### Goal
Automate legacy dump import + CSV export so we can rerun the same process for future fresh backups.

### Completed
- Added reusable script: `scripts/legacy_dump_to_csv.sh`.
- Script handles:
  - DB recreate (`dropdb` + `createdb`)
  - dump import via `psql`
  - CSV export for all public tables to `prod_backup/legacy_csv/`
  - manifest generation (`_manifest.csv`)
  - schema doc generation (`docs/legacy-db-schema.md`)
- Verified script syntax and CLI help output.

### Note
- Current workspace no longer contains the raw SQL backup file at `prod_backup/PostgreSQL.sql`, so a full end-to-end rerun now requires passing a fresh dump path via `--dump`.

## 2026-03-08 (cleanup workflow)

### Goal
Keep only users `191` and `192`, remove trips connected to any other users, and export cleaned CSVs.

### Completed
- Updated `scripts/legacy_dump_to_csv.sh` with DB-side cleanup mode:
  - `--keep-users 191,192` to apply SQL cleanup before export
  - `--skip-import` to run cleanup/export on an already-loaded DB
- Executed:
  - `scripts/legacy_dump_to_csv.sh --skip-import --keep-users 191,192 --csv-dir prod_backup/legacy_csv_clean --schema-doc docs/legacy-db-schema-clean.md`
- Generated cleaned CSV set at `prod_backup/legacy_csv_clean/`.

### Validation
- `users.csv` contains only IDs `191` and `192`.
- `trips.csv` has no trips authored by other users.
- `users_trips.csv` has no rows for other users.
- `trip_invites.csv` is empty after cleanup.

## 2026-03-08 (conversion for new app import)

### Goal
Convert cleaned legacy CSV data into an import-ready format for the new Hamster Travel app.

### Completed
- Added conversion script: `scripts/convert_legacy_csv_for_import.py`.
- Script converts legacy entities into per-trip JSON bundles with:
  - `day_index` derived from old `days`
  - geo references via `geonames` IDs
  - legacy user IDs preserved for env-specific mapping at import time
- Generated import package in `prod_backup/import_ready/`:
  - `trips.jsonl`
  - `warnings.jsonl`
  - `summary.json`
  - `legacy_user_mapping.template.json`
  - `day_index_map.csv`
- Added format documentation: `docs/legacy-import-format.md`.

### Notes
- Conversion currently emits warnings for lossy/fallback cases (for example missing transfer times, unknown transfer types, multi-city days).
- Warnings are tracked in `prod_backup/import_ready/warnings.jsonl` and should be reviewed before final importer implementation.

## 2026-03-08 (import implementation)

### Goal
Implement actual import code for `prod_backup/import_ready/trips.jsonl`.

### Completed
- Added importer module: `lib/hamster_travel/legacy_import/trips_importer.ex`.
- Added mix task: `mix legacy.import_trips` in `lib/mix/tasks/legacy.import_trips.ex`.
- Import task supports:
  - `--bundle-dir`
  - `--user-map-file`
  - `--limit`
  - `--skip-missing-cities`
  - `--continue-on-error`
- Import docs updated in `docs/legacy-import-format.md`.

### Validation
- `mix format` passed.
- `mix compile` passed.
- `mix credo --strict` passed.
- `mix test` failed due DB connection unavailable (local Postgres not running at test time).

## 2026-03-14

### Goal
Update conversion to support multiple cities on the same trip day.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py` destination conversion logic:
  - no longer collapses each day to one city
  - preserves all distinct cities per day
  - builds overlapping destination ranges per city across consecutive days
- Re-ran conversion:
  - `uv run python scripts/convert_legacy_csv_for_import.py`
  - regenerated `prod_backup/import_ready/*`

### Validation
- `day_multiple_cities` warnings removed.
- Warning count reduced from `319` to `233`.
- Verified at least one trip (`legacy_trip_450`) now has overlapping destination cities on the same day.

## 2026-03-14 (import clean-state behavior)

### Goal
Ensure importer starts from a clean trips state on every run.

### Completed
- Updated `lib/hamster_travel/legacy_import/trips_importer.ex` to purge existing trip-related planning data before import.
- Cleanup runs in FK-safe order and includes existing `trips` and `trips_tombstones`.
- Updated import docs/task docs to clearly mark this destructive behavior.

### Validation
- `mix format` passed.
- `mix compile` passed.
- `mix credo --strict` passed.
- `mix test` passed (with existing ChromicPDF timeout error logs in output, but no test failures).

## 2026-03-15

### Goal
Prepare dev user mapping for legacy import test run.

### Completed
- Checked users in `hamster_travel_dev`.
- Found target users:
  - `bunny@hamsters.test`
  - `hamster@hamsters.test`
- Created mapping file: `prod_backup/import_ready/legacy_user_mapping.dev.json`
  - `191 -> bunny@hamsters.test`
  - `192 -> hamster@hamsters.test`

## 2026-03-15 (dev import execution)

### Goal
Run the legacy importer locally against `hamster_travel_dev` using the dev user mapping.

### Command Run
```bash
mix legacy.import_trips \
  --bundle-dir prod_backup/import_ready \
  --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json \
  --continue-on-error
```

### Result
- Import finished successfully (exit code `0`).
- Summary:
  - `total`: `144`
  - `imported`: `134`
  - `failed`: `10`

### Known Failed Trips
- `legacy_trip_450` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_459` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_463` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_468` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_477` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_492` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_493` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_496` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_498` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_592` - missing city in geo data (`destination city geonames not found: "3372783"`)

### Post-run DB Counts (`hamster_travel_dev`)
- `trips`: `134`
- `destinations`: `256`
- `accommodations`: `783`
- `transfers`: `402`
- `activities`: `1906`
- `day_expenses`: `329`
- `notes`: `235`
- `trip_participants`: `92`

## 2026-03-15 (money + transfer rendering fix)

### Goal
Fix incorrect migrated money values (100x inflated) and trip page crash on transfers without expense.

### Root Cause
- Importer treated legacy `amount_cents` as major currency units:
  - used `Money.new(currency, cents)` instead of converting subunits to money properly.
- Transfer component assumed every transfer has an expense:
  - direct access `@transfer.expense.price` caused `BadMapError` when expense is `nil`.

### Completed
- Updated importer money conversion in `lib/hamster_travel/legacy_import/trips_importer.ex`:
  - switched to `Money.from_integer(cents, currency)` for all imported expense prices.
- Updated transfer rendering in `lib/hamster_travel_web/live/planning_live/components/transfer.ex`:
  - render `<.money_display>` only when `@transfer.expense` exists.
- Re-ran local dev import:
  - `mix legacy.import_trips --bundle-dir prod_backup/import_ready --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --continue-on-error`
  - result remained `total: 144`, `imported: 134`, `failed: 10` (same 10 known failures).

### Validation
- Quality checks:
  - `mix test` -> `606` tests, `0` failures.
  - `mix credo --strict` -> no issues.
- Cabo Verde trip budgets after fix:
  - `kto-byl-na-kabo-verde-zimnie-kanikuly`: `€5,146.80` (was `€514,680.00` before fix).
  - `kto-byl-na-kabo-verde`: `€10,303.56` (was `€1,030,356.00` before fix).

## 2026-03-15 (expense presence rule)

### Goal
Keep strict planning UI assumptions: migrated accommodations/transfers/activities/day-expenses must always have an `expense` row, using `0` when legacy amount is missing.

### Completed
- Reverted UI-level conditional money rendering workarounds.
- Updated importer (`lib/hamster_travel/legacy_import/trips_importer.ex`) to always attach an expense for:
  - accommodations
  - transfers
  - activities
  - day expenses
- When legacy expense is missing/invalid, importer now creates fallback:
  - `price = 0` (trip currency)
  - non-empty default name (`Legacy ... expense` / `Transfer expense` / entity name)

### Validation
- Re-ran import:
  - `MIX_BUILD_PATH=_build_codex mix legacy.import_trips --bundle-dir prod_backup/import_ready --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --continue-on-error`
  - Result: `total 144`, `imported 134`, `failed 10` (same known 10 failures).
- DB integrity checks in `hamster_travel_dev`:
  - `accommodations_without_expense = 0`
  - `transfers_without_expense = 0`
  - `activities_without_expense = 0`
  - `day_expenses_without_expense = 0`
- Route check for problematic trip:
  - `GET /trips/kto-byl-na-kabo-verde-zimnie-kanikuly` returns `200` (no FunctionClauseError/BadMapError).
- Quality checks:
  - `MIX_BUILD_PATH=_build_codex mix test` -> `606` tests, `0` failures
  - `MIX_BUILD_PATH=_build_codex mix credo --strict` -> no issues

## 2026-03-15 (food expense semantics fix)

### Goal
Fix food migration where old per-day food rate was being imported as total trip amount.

### Root Cause
- In legacy `caterings`, `amount_cents` is a **per-day-per-person** value.
- Converter treated it as a trip total and divided by `days * people`, producing tiny daily values (for example `0.90` instead of `30.00`).

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py` food conversion logic:
  - compute row total as `amount_cents * days_count * persons_count`
  - aggregate row totals into trip food total
  - derive `price_per_day_cents` from aggregated total
  - keep `days_count` from trip duration (fallback to summed legacy days when needed)
- Re-generated bundle:
  - `uv run python scripts/convert_legacy_csv_for_import.py`
- Re-imported dev data:
  - `MIX_BUILD_PATH=_build_codex mix legacy.import_trips --bundle-dir prod_backup/import_ready --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --continue-on-error`

### Validation
- `legacy_trip_605` converted food now:
  - `price_per_day_cents = 3000`
  - `days_count = 11`
  - `people_count = 3`
  - total food cents = `99000`
- Dev app values for `kto-byl-na-kabo-verde`:
  - food: `€30.00` per day, `11` days, `3` people
  - food total: `€990.00`
  - trip budget: `€11,263.86` (matches legacy expected value)

## 2026-03-15 (migrate + no string trimming in importer)

### Goal
Run DB migrations and remove string trimming/truncation behavior in trip import.

### Completed
- Ran migration:
  - `mix ecto.migrate`
  - Result: `Migrations already up`
- Updated `lib/hamster_travel/legacy_import/trips_importer.ex`:
  - removed trimming from mapped user value normalization
  - removed trimming from `blank_to_nil/1` (only exact empty string becomes `nil`)
  - removed all string truncation behavior (`truncate_string/2` now returns input as-is)
  - removed line-level `String.trim` from JSONL loading path

### Validation
- `MIX_BUILD_PATH=_build_codex mix format lib/hamster_travel/legacy_import/trips_importer.ex`
- `MIX_BUILD_PATH=_build_codex mix compile`
- Compile passed.

## 2026-03-15 (rich content conversion + note titles)

### Goal
Align migrated legacy notes/descriptions with the new app rich-text format and remove legacy short-description import noise.

### Completed
- Updated converter: `scripts/convert_legacy_csv_for_import.py`
  - removed legacy short-description note creation completely
  - renamed legacy trip comment note title to `Отчет о путешествии`
  - added trip-level food description note titled `Еда`
  - converted legacy plain text to rich HTML for:
    - trip report note text
    - day comment note text
    - activity descriptions
    - accommodation notes
    - transfer notes
  - preserved line/paragraph structure using `<p>` and `<br>`
  - converted day links to rich anchor HTML
- Re-generated import bundle:
  - `uv run python scripts/convert_legacy_csv_for_import.py`

### Validation
- Bundle checks (`prod_backup/import_ready/trips.jsonl`):
  - `rows = 144`
  - `legacy_short = 0`
  - `report_count = 37`, `report_with_p = 37`
  - `report_multiline_marked = 37` (contains `<br>` or multiple paragraphs)
  - `food_note_count = 107`, `food_with_p = 107`
  - rich descriptions present:
    - `activity_html = 1931`
    - `accommodation_html = 108`
    - `transfer_html = 213`

## 2026-03-15 (food note cleanup)

### Goal
Keep food note content limited to legacy descriptive text only (without derived rate/period lines).

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py`:
  - `build_food_note_html/1` now includes only catering `name` and `description`.
  - Removed generated lines:
    - `Ставка: ...`
    - `Период: ...`
- Re-generated bundle:
  - `uv run python scripts/convert_legacy_csv_for_import.py`

### Validation
- Checked `prod_backup/import_ready/trips.jsonl`:
  - food notes containing `Ставка:`: `0`
  - food notes containing `Период:`: `0`

## 2026-03-15 (food note title rename)

### Goal
Use concise food note title required for import: `Еда`.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py`:
  - food note title changed from `Описание расходов на еду` to `Еда`.
- Re-generated bundle:
  - `uv run python scripts/convert_legacy_csv_for_import.py`

### Validation
- Checked `prod_backup/import_ready/trips.jsonl` note titles:
  - `Еда`: `106`
  - `Описание расходов на еду`: `0`

## 2026-03-15 (conversion + import rerun)

### Goal
Re-run full conversion and import after latest note-format/title adjustments.

### Commands Run
```bash
uv run python scripts/convert_legacy_csv_for_import.py
MIX_BUILD_PATH=_build_codex mix legacy.import_trips \
  --bundle-dir prod_backup/import_ready \
  --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json \
  --continue-on-error
```

### Result
- Conversion:
  - converted trips: `144`
  - warnings: `233`
- Import:
  - `total`: `144`
  - `imported`: `134`
  - `failed`: `10`

### Known Failed Trips
- `legacy_trip_450` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_459` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_463` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_468` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_477` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_492` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_493` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_496` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_498` - transfer validation (`arrival_city_id must be different from departure city`)
- `legacy_trip_592` - missing destination city geonames (`3372783`)

## 2026-03-15 (geonames remap for Ponta Delgada)

### Goal
Handle legacy geonames ID not present in new geo seed.

### Completed
- Updated converter `scripts/convert_legacy_csv_for_import.py`:
  - added geonames remap table:
    - `3372783 -> 6941014` (Ponta Delgada)
  - applied remap in legacy city-id to geonames conversion path.
- Re-generated bundle:
  - `uv run python scripts/convert_legacy_csv_for_import.py`

### Validation
- `legacy_trip_592` now references `6941014` in:
  - destinations
  - transfer departure/arrival city geonames fields

## 2026-03-15 (food note requires description)

### Goal
Do not create `Еда` notes when legacy catering row has only a name and no description text.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py`:
  - `build_food_note_html/1` now skips catering rows with empty `description`.
  - `Еда` note is created only from rows that include non-empty description text.
- Re-generated bundle:
  - `uv run python scripts/convert_legacy_csv_for_import.py`

### Validation
- Compared expected vs generated food-note trips:
  - trips with non-empty catering descriptions: `61`
  - trips with `Еда` note in `trips.jsonl`: `61`
  - unexpected `Еда` notes for name-only rows: `0`

## 2026-03-15 (post-pull conversion + import rerun)

### Goal
Re-run conversion/import after syncing latest `master`.

### Commands Run
```bash
uv run python scripts/convert_legacy_csv_for_import.py
MIX_BUILD_PATH=_build_codex mix legacy.import_trips \
  --bundle-dir prod_backup/import_ready \
  --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json \
  --continue-on-error
```

### Result
- Conversion:
  - converted trips: `144`
  - warnings: `233`
- Import:
  - `total`: `144`
  - `imported`: `144`
  - `failed`: `0`

### Validation
- Import log (`/tmp/legacy_import_latest.log`) contains final summary with no failures.

## 2026-04-28 (warning inspection)

### Goal
Inspect conversion warnings and investigate one warning type in detail.

### Warning Summary (`prod_backup/import_ready/warnings.jsonl`)
- `transfer_missing_departure_time`: `103`
- `transfer_missing_arrival_time`: `102`
- `transfer_missing_city`: `15`
- `transfer_unknown_mode`: `13`
- Total warnings: `233`

### Investigation: `transfer_missing_city` (`15`)

Root cause analysis against `legacy_csv_clean/transfers.csv` + `cities.csv`:
- `empty_city_to_id`: `8`
- `empty_city_from_id`: `7`
- No cases where city id existed but city geonames mapping was missing.

Conclusion:
- This warning type is caused by incomplete legacy transfer rows (missing one side of route), not by missing geo dictionaries.
- A simple fallback using same-day destination city can recover only `1/15` rows; most rows remain ambiguous because either:
  - day has no destination places, or
  - day destination equals the known transfer side (so opposite side cannot be inferred reliably).

## 2026-04-28 (transfer missing-time fallback)

### Goal
When transfer time is missing/invalid, use midnight of the transfer day date instead of epoch fallback.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py`:
  - added `day_midnight_iso_utc/1` helper for `YYYY-MM-DD -> YYYY-MM-DDT00:00:00Z`
  - transfer fallback now uses `days.date_when` midnight for:
    - missing departure time
    - missing arrival time
  - keeps `1970-01-01T00:00:00Z` only as last-resort fallback when day date is unavailable.

### Validation
- Re-generated bundle and checked warnings + payload:
  - sample warning changed from epoch to day date:
    - `transfer 1221`: `fallback to 2014-02-23T00:00:00Z`
  - sample payload values:
    - `legacy_trip_441`, transfer `1221`:
      - `departure_time = 2014-02-23T00:00:00Z`
      - `arrival_time = 2014-02-23T00:00:00Z`

## 2026-05-03 (archived/deleted-trip check)

### Goal
Verify whether legacy trips that appear deleted/archived are still included in conversion output.

### Findings
- Legacy source row for `FullStackFest 2016` (`trip_id=500`) has `archived = t`.
- The trip is currently included in converted bundle (`prod_backup/import_ready/trips.jsonl`).
- Current converter does not filter archived trips.

### Counts
- `legacy_csv_clean/trips.csv`:
  - total: `144`
  - archived: `47`
  - active: `97`
- Converted bundle (`trips.jsonl`):
  - total: `144`
  - archived trips included: `47`

## 2026-05-03 (skip archived trips)

### Goal
Exclude archived legacy trips from conversion output.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py`:
  - skip trip rows where `archived = t/true/1`.
- Re-generated bundle:
  - `UV_CACHE_DIR=.uv-cache uv run python scripts/convert_legacy_csv_for_import.py`

### Validation
- `legacy_csv_clean/trips.csv` active trips: `97`
- Converted `trips.jsonl` total: `97`
- Archived trips included in bundle: `0`
- `FullStackFest 2016` (`trip_id=500`) is no longer present in bundle.

## 2026-05-03 (local reimport after archived filter)

### Goal
Re-import locally after excluding archived trips from conversion output.

### Command Run
```bash
MIX_BUILD_PATH=_build_codex mix legacy.import_trips \
  --bundle-dir prod_backup/import_ready \
  --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json \
  --continue-on-error
```

### Result
- `total`: `97`
- `imported`: `97`
- `failed`: `0`

## 2026-05-03 (Açores transfer 00:00 investigation)

### Goal
Investigate why transfer `Франкфурт-на-Майне -> Берлин` in `Азорские острова` is imported with `00:00`.

### Findings
- Affected legacy transfer row: `transfer_id=2049` (`LH202`, `FRA -> BER`).
- Legacy source has valid times with fractional seconds:
  - `start_time = 2025-05-04 21:15:19.214`
  - `end_time = 2025-05-04 22:25:19.215`
- Converter currently parses transfer time with strict format `%Y-%m-%d %H:%M:%S` only.
- Because of `.SSS` fractional part, parsing fails and fallback logic applies day-midnight:
  - `2025-08-03T00:00:00Z` for this trip day.

### Scope
- Not only one transfer:
  - `transfer_missing_departure_time`: `59` warnings total, `14` of them have non-empty source times with fractional seconds.
  - `transfer_missing_arrival_time`: `58` warnings total, `13` of them have non-empty source times with fractional seconds.

## 2026-05-03 (fractional-seconds timestamp support + rerun)

### Goal
Parse legacy transfer timestamps that include fractional seconds and avoid incorrect `00:00` fallbacks.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py`:
  - `parse_timestamp_to_iso_utc/1` now accepts both formats:
    - `%Y-%m-%d %H:%M:%S`
    - `%Y-%m-%d %H:%M:%S.%f`
- Re-generated bundle:
  - `UV_CACHE_DIR=.uv-cache uv run python scripts/convert_legacy_csv_for_import.py`
- Re-imported locally:
  - `MIX_BUILD_PATH=_build_codex mix legacy.import_trips --bundle-dir prod_backup/import_ready --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json --continue-on-error`

### Validation
- Warning reduction after conversion:
  - `transfer_missing_departure_time`: `45` (was `59`)
  - `transfer_missing_arrival_time`: `45` (was `58`)
- `Азорские острова` / `LH202` (`FRA -> BER`) converted times:
  - `departure_time = 2025-05-04T21:15:19Z`
  - `arrival_time = 2025-05-04T22:25:19Z`
- Local DB after import (`hamster_travel_dev`) confirms:
  - `azorskie-ostrova | FRA -> BER | 2025-05-04 21:15:19 -> 2025-05-04 22:25:19 | Lufthansa | LH202`
- Import result:
  - `total: 97`
  - `imported: 97`
  - `failed: 0`

## 2026-05-03 (transfer date anchoring validation for sorting)

### Goal
Fix and validate wrong transfer ordering caused by legacy timestamp date parts not matching trip day dates.

### Completed
- Converter now anchors transfer `departure_time/arrival_time` to `days.date_when` while preserving the clock time.
- If anchored arrival is earlier than anchored departure, arrival is shifted to next day (overnight transfer case).

### Validation (trip: `Азорские острова`)
- Day 9 transfers in `hamster_travel_dev` are now stored as:
  - `LH1549`: `2025-08-03 13:30 -> 2025-08-03 20:15`
  - `LH202`: `2025-08-03 21:15 -> 2025-08-03 22:25`
- With these timestamps, UI sorting by `departure_time` is chronologically correct (`LH1549` before `LH202`).

## 2026-05-03 (food days_count fix)

### Goal
Fix migrated food expense day counts (total amount was correct, days were inflated to trip duration).

### Root Cause
- In `scripts/convert_legacy_csv_for_import.py`, food `days_count` was set from trip `day_count`.
- This overrode legacy catering `days_count` and forced a recomputed lower `price_per_day` to keep the same total.

### Completed
- Updated converter to derive food `days_count` from legacy catering rows:
  - `days_count = sum(caterings.days_count)` (fallback min `1`).
- Re-generated import bundle and re-imported dev DB.

### Validation
- Programmatic check against `legacy_csv_clean/caterings.csv`:
  - `checked trips with food: 91`
  - `mismatch count: 0`
- Import result:
  - `total: 97`
  - `imported: 97`
  - `failed: 0`

## 2026-05-09 (day link title hostnames)

### Goal
Replace placeholder note title `Legacy day link` with a hostname-derived title.

### Completed
- Updated converter day-link note title logic in `scripts/convert_legacy_csv_for_import.py`:
  - parse hostname from URL
  - drop `www.` prefix
  - capitalize first letter
  - treat existing `description == "Legacy day link"` as placeholder and replace with hostname title
- Re-generated bundle and re-imported dev DB.

### Validation
- Converted bundle contains no `Legacy day link` titles.
- Post-import DB check: `legacy_day_link_notes=0`.
- Import result: `total=97`, `imported=97`, `failed=0`.

## 2026-05-09 (activity ordering by legacy order_index)

### Goal
Preserve legacy per-day activity order during migration.

### Root Cause
- Converter sorted activities by legacy `id` instead of legacy `order_index`.

### Completed
- Updated `scripts/convert_legacy_csv_for_import.py` activities sort key:
  - primary: `order_index`
  - tie-breaker: `id`
- Re-generated bundle and re-imported dev DB.

### Validation
- Affected trip (`Свадьба в готическом замке, море пива и знакомство с абсентной феей`), day 1 now imports in legacy order:
  1. Заселение и встреча с организатором свадьбы
  2. Стракова Академия
  3. Самая узкая улочка Праги
  4. Музей Франца Кафки
  5. Карлов мост
  6. Карлова улица
  7. Церковь св. Сальватора
  8. Клементинум
  9. Храм Святого Франциска Ассизского
  10. Танцующий дом
  11. Церковь Святого Николая (Мала-Страна)
  12. Остров Кампа
- Import result: `total=97`, `imported=97`, `failed=0`.

## 2026-05-09 (Hong Kong trip crash fix: destination preload)

### Symptom
- Opening trip `gonkong-aziya-kak-ona-est` crashed with:
  - `BadMapError expected a map, got nil`
  - in `planning_live/components/destination.ex`

### Root Cause
- `Geo.city_preloading_query/0` used an inner join to `regions`.
- Imported destination cities `Hong Kong` and `Macau` have `region_code = NULL`, so they were filtered out by the join and preloaded as `nil`.

### Fix
- Updated `lib/hamster_travel/geo.ex`:
  - `city_preloading_query/0`: `join Region` -> `left_join Region`
  - `get_city/1`: `join Region` -> `left_join Region`

### Validation
- For trip slug `gonkong-aziya-kak-ona-est`, destination preload now returns `nil city count = 0`.
- Hong Kong and Macau cities are now present in preloaded destination data.

## 2026-05-09 (full rerun from fresh production dump)

### Goal
Re-run the complete legacy migration pipeline from the newly provided production SQL dump.

### Input
- Dump file: `prod_backup/PostgreSQL.sql`

### Pipeline Run
1. Restore + cleanup + cleaned CSV export:
```bash
scripts/legacy_dump_to_csv.sh \
  --dump prod_backup/PostgreSQL.sql \
  --keep-users 191,192 \
  --csv-dir prod_backup/legacy_csv_clean \
  --schema-doc docs/legacy-db-schema-clean.md
```

2. Convert cleaned CSV to import bundle:
```bash
UV_CACHE_DIR=.uv-cache uv run python scripts/convert_legacy_csv_for_import.py
```

3. Import into local dev app DB:
```bash
MIX_BUILD_PATH=_build_codex mix legacy.import_trips \
  --bundle-dir prod_backup/import_ready \
  --user-map-file prod_backup/import_ready/legacy_user_mapping.dev.json \
  --continue-on-error
```

### Results
- Legacy cleanup/export snapshot after keeping users `191,192`:
  - `users: 2`
  - `trips: 145`
  - `days: 887`
  - `activities: 2406`
  - `transfers: 521`
  - `hotels: 887`
  - `expenses: 1095`
  - `external_links: 1779`
- Conversion output:
  - `Converted trips: 98`
  - `Warnings: 98`
- Import output:
  - `total: 98`
  - `imported: 98`
  - `failed: 0`

### Notes
- The importer purged existing trip-related planning data before import (expected behavior).
- This run is now the baseline for final validation.

## 2026-05-09 (post-import smoke test as Hamster user)

### Goal
Run authenticated smoke test by opening all accessible trip pages (including drafts) and ensure there are no runtime failures.

### Account Used
- `hamster@hamsters.test` (`Hamster Hamsters`)

### Method
- Logged in via local `/users/log_in` endpoint with CSRF-protected session.
- Enumerated all trip slugs accessible to this user.
- Opened each URL `/trips/:slug` with authenticated session and checked HTTP response.

### Result
- Total trip pages tested: `92`
- Draft trips tested: `13`
- Failures (non-200 or login-redirect): `0`

### Artifacts
- Trip list used: `/tmp/hamster_trips.tsv`
- Smoke result table: `/tmp/hamster_smoke_results.tsv`
