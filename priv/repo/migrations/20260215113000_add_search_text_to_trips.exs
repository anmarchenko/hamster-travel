defmodule HamsterTravel.Repo.Migrations.AddSearchTextToTrips do
  use Ecto.Migration

  def up do
    alter table(:trips) do
      add :search_text, :text, null: false, default: ""
    end

    execute """
    CREATE OR REPLACE FUNCTION refresh_trip_search_text(p_trip_id uuid)
    RETURNS void
    LANGUAGE sql
    AS $$
      UPDATE trips
      SET search_text = COALESCE(
        (
          SELECT string_agg(term, ' ')
          FROM (
            SELECT DISTINCT c.name AS term
            FROM destinations d
            JOIN cities c ON c.id = d.city_id
            WHERE d.trip_id = p_trip_id

            UNION

            SELECT DISTINCT c.name_ru AS term
            FROM destinations d
            JOIN cities c ON c.id = d.city_id
            WHERE d.trip_id = p_trip_id
              AND c.name_ru IS NOT NULL
              AND c.name_ru <> ''

            UNION

            SELECT DISTINCT country.name AS term
            FROM destinations d
            JOIN cities c ON c.id = d.city_id
            JOIN countries country ON country.iso = c.country_code
            WHERE d.trip_id = p_trip_id

            UNION

            SELECT DISTINCT country.name_ru AS term
            FROM destinations d
            JOIN cities c ON c.id = d.city_id
            JOIN countries country ON country.iso = c.country_code
            WHERE d.trip_id = p_trip_id
              AND country.name_ru IS NOT NULL
              AND country.name_ru <> ''
          ) terms
        ),
        ''
      )
      WHERE id = p_trip_id;
    $$;
    """

    execute """
    CREATE OR REPLACE FUNCTION refresh_trip_search_text_on_destination_change()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF TG_OP = 'DELETE' THEN
        PERFORM refresh_trip_search_text(OLD.trip_id);
        RETURN OLD;
      END IF;

      PERFORM refresh_trip_search_text(NEW.trip_id);

      IF TG_OP = 'UPDATE' AND OLD.trip_id IS DISTINCT FROM NEW.trip_id THEN
        PERFORM refresh_trip_search_text(OLD.trip_id);
      END IF;

      RETURN NEW;
    END;
    $$;
    """

    execute """
    CREATE TRIGGER destinations_refresh_trip_search_text
    AFTER INSERT OR UPDATE OF trip_id, city_id OR DELETE ON destinations
    FOR EACH ROW
    EXECUTE FUNCTION refresh_trip_search_text_on_destination_change();
    """

    execute """
    CREATE INDEX trips_search_vector_idx
    ON trips
    USING gin (
      (
        setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(search_text, '')), 'B')
      )
    );
    """

    execute """
    SELECT refresh_trip_search_text(id)
    FROM trips;
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS trips_search_vector_idx"
    execute "DROP TRIGGER IF EXISTS destinations_refresh_trip_search_text ON destinations"
    execute "DROP FUNCTION IF EXISTS refresh_trip_search_text_on_destination_change()"
    execute "DROP FUNCTION IF EXISTS refresh_trip_search_text(uuid)"

    alter table(:trips) do
      remove :search_text
    end
  end
end
