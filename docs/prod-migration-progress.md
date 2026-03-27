# Production Migration Progress

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
