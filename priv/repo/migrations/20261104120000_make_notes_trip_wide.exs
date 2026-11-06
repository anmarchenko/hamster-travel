defmodule HamsterTravel.Repo.Migrations.MakeNotesTripWide do
  use Ecto.Migration

  def up do
    execute """
    UPDATE notes
    SET rank = ordered.rank
    FROM (
      SELECT id,
        row_number() OVER notebook_order * 4294967295
          / (count(*) OVER (PARTITION BY trip_id) + 1) - 2147483648 AS rank
      FROM notes
      WINDOW notebook_order AS (PARTITION BY trip_id ORDER BY day_index ASC NULLS FIRST, rank, id)
    ) AS ordered
    WHERE notes.id = ordered.id
    """

    drop index(:notes, [:trip_id, :day_index])

    alter table(:notes) do
      remove :day_index
    end
  end

  def down do
    alter table(:notes) do
      add :day_index, :integer
    end

    create index(:notes, [:trip_id, :day_index])
  end
end
