BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;
SET LOCAL search_path = pg_catalog, public;
SET LOCAL statement_timeout = '60s';

SELECT string_agg(version::text, ',' ORDER BY version) IS DISTINCT FROM :'reviewed_migrations' AS schema_drift
FROM schema_migrations
\gset
\if :schema_drift
DO $$ BEGIN RAISE EXCEPTION 'Production migrations differ from the reviewed dev travel schema'; END $$;
\endif

-- Require exactly one source account.
SELECT id AS source_id FROM users WHERE lower(name) = lower('Andrey Marchenko')
\gset

COPY (
  WITH friends_circle AS (
    SELECT :'source_id'::uuid AS user_id
    UNION
    SELECT friend_id FROM friendships WHERE user_id = :'source_id'::uuid
  ),
  visible_trips AS (
    -- Mirrors Planning.Policy.user_trip_visibility_scope/2.
    SELECT * FROM trips
    WHERE NOT private OR author_id IN (SELECT user_id FROM friends_circle)
      OR id IN (SELECT trip_id FROM trip_participants WHERE user_id = :'source_id'::uuid)
  ),
  visible_backpacks AS (
    -- Mirrors Packing.Policy.user_scope/2.
    SELECT * FROM backpacks WHERE user_id IN (SELECT user_id FROM friends_circle)
  ),
  selected_destinations AS (
    SELECT * FROM destinations WHERE trip_id IN (SELECT id FROM visible_trips)
  ),
  selected_transfers AS (
    SELECT * FROM transfers WHERE trip_id IN (SELECT id FROM visible_trips)
  ),
  selected_categories AS (
    SELECT * FROM budget_categories WHERE trip_id IN (SELECT id FROM visible_trips)
  ),
  selected_cities AS (
    SELECT * FROM cities WHERE id IN (
      SELECT city_id FROM selected_destinations
      UNION SELECT departure_city_id FROM selected_transfers
      UNION SELECT arrival_city_id FROM selected_transfers
    )
  ),
  selected_lists AS (
    SELECT * FROM backpack_lists WHERE backpack_id IN (SELECT id FROM visible_backpacks)
  ),
  -- Match the img element emitted by the rich text editor, including quoted attributes.
  image_tag AS (
    SELECT $pattern$<img(?=[[:space:]/>])(?:[^"'<>]|"[^"]*"|'[^']*')*>$pattern$ AS pattern
  )
  SELECT jsonb_build_object(
    'trips', ARRAY(
      SELECT to_jsonb(t) - ARRAY['author_id', 'cover', 'search_text'] FROM visible_trips t
    ),
    'backpacks', ARRAY(SELECT to_jsonb(b) - 'user_id' FROM visible_backpacks b),
    'backpack_lists', ARRAY(SELECT to_jsonb(l) FROM selected_lists l),
    'backpack_items', ARRAY(
      SELECT to_jsonb(i) FROM backpack_items i WHERE backpack_list_id IN (SELECT id FROM selected_lists)
    ),
    'destinations', ARRAY(SELECT to_jsonb(d) FROM selected_destinations d),
    'accommodations', ARRAY(
      SELECT to_jsonb(a) || jsonb_build_object('note', regexp_replace(a.note, pattern, '', 'gi'))
      FROM accommodations a CROSS JOIN image_tag WHERE trip_id IN (SELECT id FROM visible_trips)
    ),
    'transfers', ARRAY(
      SELECT to_jsonb(t) || jsonb_build_object('note', regexp_replace(t.note, pattern, '', 'gi'))
      FROM selected_transfers t CROSS JOIN image_tag
    ),
    'activities', ARRAY(
      SELECT to_jsonb(a) || jsonb_build_object('description', regexp_replace(a.description, pattern, '', 'gi'))
      FROM activities a CROSS JOIN image_tag WHERE trip_id IN (SELECT id FROM visible_trips)
    ),
    'day_expenses', ARRAY(
      SELECT to_jsonb(d) FROM day_expenses d WHERE trip_id IN (SELECT id FROM visible_trips)
    ),
    'notes', ARRAY(
      SELECT to_jsonb(n) || jsonb_build_object('text', regexp_replace(n.text, pattern, '', 'gi'))
      FROM notes n CROSS JOIN image_tag WHERE trip_id IN (SELECT id FROM visible_trips)
    ),
    'budget_categories', ARRAY(SELECT to_jsonb(b) FROM selected_categories b),
    'budget_category_food_settings', ARRAY(
      SELECT to_jsonb(f) FROM budget_category_food_settings f
      WHERE budget_category_id IN (SELECT id FROM selected_categories)
    ),
    'expenses', ARRAY(SELECT to_jsonb(e) FROM expenses e WHERE trip_id IN (SELECT id FROM visible_trips)),
    'cities', ARRAY(SELECT to_jsonb(c) FROM selected_cities c),
    'regions', ARRAY(
      SELECT to_jsonb(r) FROM regions r
      WHERE (country_code, region_code) IN (SELECT country_code, region_code FROM selected_cities)
    ),
    'countries', ARRAY(
      SELECT to_jsonb(c) FROM countries c WHERE iso IN (SELECT country_code FROM selected_cities)
    )
  )
) TO STDOUT;

COMMIT;
