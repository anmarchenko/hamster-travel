BEGIN;
SET LOCAL search_path = pg_catalog, public;
SET LOCAL lock_timeout = '5s';

DO $$
BEGIN
  IF current_database() <> 'hamster_travel_dev' THEN
    RAISE EXCEPTION 'The target must be hamster_travel_dev';
  END IF;
END
$$;

\if :replace
-- Serialize replacement with Ecto migrations for the duration of this transaction.
LOCK TABLE schema_migrations IN SHARE MODE;
\endif
SELECT string_agg(version::text, ',' ORDER BY version) IS DISTINCT FROM :'reviewed_migrations' AS schema_drift
FROM schema_migrations
\gset
\if :schema_drift
DO $$ BEGIN RAISE EXCEPTION 'Dev migrations differ from the reviewed dev travel schema'; END $$;
\endif

-- Require the seeded Bunny account before making any changes.
SELECT id AS bunny_id FROM users WHERE email = 'bunny@hamsters.test'
\gset

CREATE TEMP TABLE refresh_snapshot (payload jsonb NOT NULL) ON COMMIT DROP;
\copy refresh_snapshot (payload) FROM PSTDIN

SELECT jsonb_array_length(payload->'trips') AS trip_count,
       jsonb_array_length(payload->'backpacks') AS backpack_count
FROM refresh_snapshot
WHERE payload ?& ARRAY['trips', 'backpacks']
\gset
\echo Production snapshot contains :trip_count trips and :backpack_count backpacks.

\if :replace
-- Keep the wipe and import in one transaction. List dependencies explicitly
-- so a new foreign key stops the refresh instead of wiping additional tables.
TRUNCATE trips_tombstones, trip_participants, expenses, budget_category_food_settings,
  budget_categories, notes, day_expenses, activities, transfers, accommodations, destinations,
  trips, backpack_items, backpack_lists, backpacks RESTART IDENTITY;

-- Geo IDs differ between installations. Keep existing reference rows and add missing ones.
INSERT INTO countries (name, name_ru, iso, geonames_id, continent, currency_code,
                       currency_name, iso3, ison, inserted_at, updated_at)
SELECT c.name, c.name_ru, c.iso, c.geonames_id, c.continent, c.currency_code,
       c.currency_name, c.iso3, c.ison, c.inserted_at, c.updated_at
FROM refresh_snapshot, jsonb_populate_recordset(NULL::countries, payload->'countries') c
ON CONFLICT (iso) DO NOTHING;

INSERT INTO regions (name, name_ru, region_code, geonames_id, country_code, lat, lon, inserted_at, updated_at)
SELECT r.name, r.name_ru, r.region_code, r.geonames_id, r.country_code, r.lat, r.lon, r.inserted_at, r.updated_at
FROM refresh_snapshot, jsonb_populate_recordset(NULL::regions, payload->'regions') r
ON CONFLICT (country_code, region_code) DO NOTHING;

INSERT INTO cities (name, name_ru, region_code, geonames_id, country_code, lat, lon, population, inserted_at, updated_at)
SELECT c.name, c.name_ru, c.region_code, c.geonames_id, c.country_code, c.lat, c.lon, c.population,
       c.inserted_at, c.updated_at
FROM refresh_snapshot, jsonb_populate_recordset(NULL::cities, payload->'cities') c
ON CONFLICT (geonames_id) DO NOTHING;

CREATE TEMP TABLE refresh_city_map ON COMMIT DROP AS
SELECT source.id AS source_id, dev.id AS dev_id
FROM refresh_snapshot
CROSS JOIN LATERAL jsonb_populate_recordset(NULL::cities, payload->'cities') source
JOIN cities dev USING (geonames_id);
ALTER TABLE refresh_city_map ADD PRIMARY KEY (source_id);

INSERT INTO trips
SELECT (jsonb_populate_record(NULL::trips,
          item || jsonb_build_object('author_id', :'bunny_id'::uuid, 'cover', NULL, 'search_text', ''))).*
FROM refresh_snapshot, jsonb_array_elements(payload->'trips') item;

INSERT INTO backpacks
SELECT (jsonb_populate_record(NULL::backpacks, item || jsonb_build_object('user_id', :'bunny_id'::uuid))).*
FROM refresh_snapshot, jsonb_array_elements(payload->'backpacks') item;

INSERT INTO destinations
SELECT (jsonb_populate_record(NULL::destinations, item || jsonb_build_object(
          'city_id', (SELECT dev_id FROM refresh_city_map WHERE source_id = (item->>'city_id')::bigint)))).*
FROM refresh_snapshot, jsonb_array_elements(payload->'destinations') item;

INSERT INTO transfers
SELECT (jsonb_populate_record(NULL::transfers, item || jsonb_build_object(
          'departure_city_id', (SELECT dev_id FROM refresh_city_map
                                WHERE source_id = (item->>'departure_city_id')::bigint),
          'arrival_city_id', (SELECT dev_id FROM refresh_city_map
                              WHERE source_id = (item->>'arrival_city_id')::bigint)))).*
FROM refresh_snapshot, jsonb_array_elements(payload->'transfers') item;

-- These tables can be copied as-is, in foreign key order.
SELECT format(
  'INSERT INTO %1$I SELECT item.* FROM refresh_snapshot,
     jsonb_populate_recordset(NULL::%1$I, payload->%1$L) item',
  table_name
)
FROM unnest(ARRAY['accommodations', 'activities', 'day_expenses', 'notes', 'budget_categories',
                  'budget_category_food_settings', 'expenses', 'backpack_lists', 'backpack_items'])
     WITH ORDINALITY AS tables(table_name, load_order)
ORDER BY load_order
\gexec

-- Preserve copied IDs and leave sequences ready for the next dev insert.
DO $$
DECLARE
  table_name text;
  next_id bigint;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['destinations', 'accommodations', 'transfers', 'activities',
                                   'day_expenses', 'notes', 'budget_categories',
                                   'budget_category_food_settings', 'expenses']
  LOOP
    EXECUTE format('SELECT COALESCE(max(id) + 1, 1) FROM %I', table_name) INTO next_id;
    EXECUTE format('ALTER SEQUENCE %s RESTART WITH %s', pg_get_serial_sequence(table_name, 'id'), next_id);
  END LOOP;
END
$$;

COMMIT;
\echo Dev travel data replaced under bunny@hamsters.test.
\else
ROLLBACK;
\echo Dry run complete. Pass --replace to replace dev travel data.
\endif
