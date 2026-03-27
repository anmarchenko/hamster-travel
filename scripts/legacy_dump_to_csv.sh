#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Load a legacy SQL dump into Postgres and export all public tables to CSV.

Usage:
  scripts/legacy_dump_to_csv.sh [options]

Options:
  --dump PATH             Path to SQL dump file (default: prod_backup/PostgreSQL.sql)
  --db NAME               Target database name (default: hamster_travel_legacy_prod)
  --host HOST             Postgres host (default: localhost)
  --port PORT             Postgres port (default: 6000)
  --user USER             Postgres user (default: postgres)
  --password PASSWORD     Postgres password (default: postgres)
  --csv-dir PATH          CSV export directory (default: prod_backup/legacy_csv)
  --import-log PATH       Import log path (default: /tmp/<db>_import.log)
  --schema-doc PATH       Schema markdown output (default: docs/legacy-db-schema.md)
  --keep-users IDS        Comma-separated user IDs to keep (example: 191,192)
  --skip-import           Skip DB recreate/import and operate on existing DB
  --skip-schema-doc       Skip schema markdown generation
  -h, --help              Show this help
EOF
}

DUMP_PATH="prod_backup/PostgreSQL.sql"
DB_NAME="hamster_travel_legacy_prod"
PG_HOST="localhost"
PG_PORT="6000"
PG_USER="postgres"
PG_PASSWORD="${PGPASSWORD:-postgres}"
CSV_DIR="prod_backup/legacy_csv"
SCHEMA_DOC="docs/legacy-db-schema.md"
GENERATE_SCHEMA_DOC="1"
KEEP_USERS=""
SKIP_IMPORT="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dump)
      DUMP_PATH="$2"
      shift 2
      ;;
    --db)
      DB_NAME="$2"
      shift 2
      ;;
    --host)
      PG_HOST="$2"
      shift 2
      ;;
    --port)
      PG_PORT="$2"
      shift 2
      ;;
    --user)
      PG_USER="$2"
      shift 2
      ;;
    --password)
      PG_PASSWORD="$2"
      shift 2
      ;;
    --csv-dir)
      CSV_DIR="$2"
      shift 2
      ;;
    --import-log)
      IMPORT_LOG="$2"
      shift 2
      ;;
    --schema-doc)
      SCHEMA_DOC="$2"
      shift 2
      ;;
    --keep-users)
      KEEP_USERS="$2"
      shift 2
      ;;
    --skip-import)
      SKIP_IMPORT="1"
      shift
      ;;
    --skip-schema-doc)
      GENERATE_SCHEMA_DOC="0"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

IMPORT_LOG="${IMPORT_LOG:-/tmp/${DB_NAME}_import.log}"

for cmd in psql createdb dropdb; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

if [[ "$SKIP_IMPORT" != "1" ]] && [[ ! -f "$DUMP_PATH" ]]; then
  echo "Dump file not found: $DUMP_PATH" >&2
  exit 1
fi

export PGPASSWORD="$PG_PASSWORD"

PSQL_BASE=(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER")

if [[ "$SKIP_IMPORT" == "1" ]]; then
  echo "Skipping import; operating on existing database: $DB_NAME"
else
  echo "Ensuring compatibility role exists: librarian"
  "${PSQL_BASE[@]}" -d postgres -v ON_ERROR_STOP=1 -c \
    "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'librarian') THEN CREATE ROLE librarian; END IF; END \$\$;" \
    >/dev/null

  echo "Recreating database: $DB_NAME"
  dropdb --if-exists -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" "$DB_NAME"
  createdb -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" "$DB_NAME"

  echo "Importing dump: $DUMP_PATH"
  if ! "${PSQL_BASE[@]}" -d "$DB_NAME" -f "$DUMP_PATH" >"$IMPORT_LOG" 2>&1; then
    echo "Import failed. See log: $IMPORT_LOG" >&2
    exit 1
  fi

  ERROR_COUNT="$(grep -c '^psql:.*ERROR:' "$IMPORT_LOG" || true)"
  echo "Import complete. Logged ERROR lines: $ERROR_COUNT (details: $IMPORT_LOG)"
fi

if [[ -n "$KEEP_USERS" ]]; then
  IFS=',' read -r -a KEEP_USER_ARRAY <<< "$KEEP_USERS"
  KEEP_USERS_VALUES=""
  for user_id in "${KEEP_USER_ARRAY[@]}"; do
    user_id="$(echo "$user_id" | tr -d '[:space:]')"
    if [[ -z "$user_id" ]]; then
      continue
    fi
    if [[ ! "$user_id" =~ ^[0-9]+$ ]]; then
      echo "Invalid user id in --keep-users: $user_id" >&2
      exit 1
    fi
    if [[ -z "$KEEP_USERS_VALUES" ]]; then
      KEEP_USERS_VALUES="($user_id)"
    else
      KEEP_USERS_VALUES="$KEEP_USERS_VALUES,($user_id)"
    fi
  done

  if [[ -z "$KEEP_USERS_VALUES" ]]; then
    echo "--keep-users was provided but no valid user ids were parsed" >&2
    exit 1
  fi

  echo "Cleaning database to keep users: $KEEP_USERS"
  "${PSQL_BASE[@]}" -d "$DB_NAME" -v ON_ERROR_STOP=1 <<SQL
BEGIN;

CREATE TEMP TABLE keep_users (id bigint PRIMARY KEY);
INSERT INTO keep_users (id) VALUES $KEEP_USERS_VALUES;

DELETE FROM users
WHERE NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = users.id);

DELETE FROM cities_users
WHERE NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = cities_users.user_id);

CREATE TEMP TABLE disallowed_trips AS
SELECT t.id AS trip_id
FROM trips t
WHERE t.author_user_id IS NULL
   OR NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = t.author_user_id)
UNION
SELECT ut.trip_id
FROM users_trips ut
WHERE NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = ut.user_id)
UNION
SELECT ti.trip_id
FROM trip_invites ti
WHERE NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = ti.inviting_user_id)
   OR NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = ti.invited_user_id);

CREATE TEMP TABLE keep_trips AS
SELECT t.id AS trip_id
FROM trips t
WHERE NOT EXISTS (SELECT 1 FROM disallowed_trips dt WHERE dt.trip_id = t.id);

DELETE FROM users_trips
WHERE NOT EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = users_trips.trip_id)
   OR NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = users_trips.user_id);

DELETE FROM trip_invites
WHERE NOT EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = trip_invites.trip_id)
   OR NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = trip_invites.inviting_user_id)
   OR NOT EXISTS (SELECT 1 FROM keep_users ku WHERE ku.id = trip_invites.invited_user_id);

CREATE TEMP TABLE keep_days AS
SELECT d.id AS day_id
FROM days d
WHERE EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = d.trip_id);

CREATE TEMP TABLE keep_caterings AS
SELECT c.id AS catering_id
FROM caterings c
WHERE EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = c.trip_id);

CREATE TEMP TABLE keep_hotels AS
SELECT h.id AS hotel_id
FROM hotels h
WHERE EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = h.day_id);

CREATE TEMP TABLE keep_transfers AS
SELECT t.id AS transfer_id
FROM transfers t
WHERE EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = t.day_id);

DELETE FROM expenses
WHERE NOT (
  (expenses.expendable_type = 'Travels::Day'
   AND EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = expenses.expendable_id))
  OR
  (expenses.expendable_type = 'Travels::Catering'
   AND EXISTS (SELECT 1 FROM keep_caterings kc WHERE kc.catering_id = expenses.expendable_id))
);

DELETE FROM external_links
WHERE NOT (
  (external_links.linkable_type = 'Travels::Day'
   AND EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = external_links.linkable_id))
  OR
  (external_links.linkable_type = 'Travels::Hotel'
   AND EXISTS (SELECT 1 FROM keep_hotels kh WHERE kh.hotel_id = external_links.linkable_id))
  OR
  (external_links.linkable_type = 'Travels::Transfer'
   AND EXISTS (SELECT 1 FROM keep_transfers kt WHERE kt.transfer_id = external_links.linkable_id))
);

DELETE FROM activities
WHERE NOT EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = activities.day_id);

DELETE FROM hotels
WHERE NOT EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = hotels.day_id);

DELETE FROM places
WHERE NOT EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = places.day_id);

DELETE FROM transfers
WHERE NOT EXISTS (SELECT 1 FROM keep_days kd WHERE kd.day_id = transfers.day_id);

DELETE FROM documents
WHERE NOT EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = documents.trip_id);

DELETE FROM caterings
WHERE NOT EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = caterings.trip_id);

DELETE FROM days
WHERE NOT EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = days.trip_id);

DELETE FROM trips
WHERE NOT EXISTS (SELECT 1 FROM keep_trips kt WHERE kt.trip_id = trips.id);

COMMIT;
SQL

  echo "Cleanup complete."
  "${PSQL_BASE[@]}" -d "$DB_NAME" -F $'\t' -Atc \
    "SELECT 'users', count(*) FROM users
     UNION ALL SELECT 'trips', count(*) FROM trips
     UNION ALL SELECT 'users_trips', count(*) FROM users_trips
     UNION ALL SELECT 'days', count(*) FROM days
     UNION ALL SELECT 'activities', count(*) FROM activities
     UNION ALL SELECT 'hotels', count(*) FROM hotels
     UNION ALL SELECT 'places', count(*) FROM places
     UNION ALL SELECT 'transfers', count(*) FROM transfers
     UNION ALL SELECT 'expenses', count(*) FROM expenses
     UNION ALL SELECT 'external_links', count(*) FROM external_links
     ORDER BY 1;" \
  | while IFS=$'\t' read -r label cnt; do
      echo "  ${label}: ${cnt}"
    done
fi

mkdir -p "$CSV_DIR"
rm -f "$CSV_DIR"/*.csv

echo "Exporting public tables to: $CSV_DIR"
mapfile -t TABLES < <("${PSQL_BASE[@]}" -d "$DB_NAME" -Atc \
  "SELECT table_name
   FROM information_schema.tables
   WHERE table_schema='public' AND table_type='BASE TABLE'
   ORDER BY table_name")

for table in "${TABLES[@]}"; do
  "${PSQL_BASE[@]}" -d "$DB_NAME" -c \
    "COPY public.\"$table\" TO STDOUT WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')" \
    >"$CSV_DIR/$table.csv"
  echo "  exported $table.csv"
done

{
  echo "table,csv_file,bytes"
  for table in "${TABLES[@]}"; do
    file="$CSV_DIR/$table.csv"
    bytes="$(wc -c <"$file" | tr -d ' ')"
    echo "$table,$table.csv,$bytes"
  done
} >"$CSV_DIR/_manifest.csv"

echo "CSV export complete: ${#TABLES[@]} tables"
echo "Manifest: $CSV_DIR/_manifest.csv"

if [[ "$GENERATE_SCHEMA_DOC" == "1" ]]; then
  mkdir -p "$(dirname "$SCHEMA_DOC")"
  echo "Generating schema doc: $SCHEMA_DOC"
  {
    echo "# Legacy Database Schema"
    echo
    echo "- Source DB: \`$DB_NAME\`"
    echo "- Host: \`$PG_HOST:$PG_PORT\`"
    echo "- Schema: \`public\`"
    echo "- Generated at: \`$(date -u +"%Y-%m-%d %H:%M:%SZ")\`"
    echo
    echo "## Tables"
    echo

    for table in "${TABLES[@]}"; do
      row_count="$("${PSQL_BASE[@]}" -d "$DB_NAME" -Atc "SELECT count(*) FROM public.\"$table\";")"
      pk_cols="$("${PSQL_BASE[@]}" -d "$DB_NAME" -Atc "
        SELECT string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position)
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
         AND tc.table_name = kcu.table_name
        WHERE tc.table_schema = 'public'
          AND tc.table_name = '$table'
          AND tc.constraint_type = 'PRIMARY KEY';")"
      fk_count="$("${PSQL_BASE[@]}" -d "$DB_NAME" -Atc "
        SELECT count(*)
        FROM information_schema.table_constraints
        WHERE table_schema='public'
          AND table_name='$table'
          AND constraint_type='FOREIGN KEY';")"

      echo "### $table"
      echo
      echo "- Rows: \`$row_count\`"
      if [[ -n "$pk_cols" ]]; then
        echo "- Primary key: \`$pk_cols\`"
      else
        echo "- Primary key: _(none)_"
      fi
      echo "- Foreign keys: \`$fk_count\`"
      echo
      echo "| Column | Type | Nullable | Default |"
      echo "|---|---|---|---|"

      "${PSQL_BASE[@]}" -d "$DB_NAME" -F $'\t' -Atc "
        SELECT c.column_name,
               c.udt_name ||
               CASE
                 WHEN c.data_type IN ('character varying','character') AND c.character_maximum_length IS NOT NULL
                   THEN '(' || c.character_maximum_length || ')'
                 WHEN c.data_type='numeric' AND c.numeric_precision IS NOT NULL
                   THEN '(' || c.numeric_precision || COALESCE(',' || c.numeric_scale, '') || ')'
                 ELSE ''
               END,
               CASE WHEN c.is_nullable='YES' THEN 'YES' ELSE 'NO' END,
               COALESCE(replace(c.column_default, '|', '\|'), '')
        FROM information_schema.columns c
        WHERE c.table_schema='public' AND c.table_name='$table'
        ORDER BY c.ordinal_position;" \
      | while IFS=$'\t' read -r col typ nullable def; do
          echo "| \`$col\` | \`$typ\` | $nullable | $def |"
        done

      echo
      echo "#### Foreign Key Details"
      echo
      if [[ "$fk_count" == "0" ]]; then
        echo "_(none)_"
      else
        echo "| Constraint | Column | References |"
        echo "|---|---|---|"
        "${PSQL_BASE[@]}" -d "$DB_NAME" -F $'\t' -Atc "
          SELECT tc.constraint_name,
                 kcu.column_name,
                 ccu.table_name || '.' || ccu.column_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
           AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
           AND ccu.table_schema = tc.table_schema
          WHERE tc.table_schema='public'
            AND tc.table_name='$table'
            AND tc.constraint_type='FOREIGN KEY'
          ORDER BY tc.constraint_name, kcu.ordinal_position;" \
        | while IFS=$'\t' read -r c_name c_col c_ref; do
            echo "| \`$c_name\` | \`$c_col\` | \`$c_ref\` |"
          done
      fi
      echo
    done
  } >"$SCHEMA_DOC"
fi

echo "Done."
