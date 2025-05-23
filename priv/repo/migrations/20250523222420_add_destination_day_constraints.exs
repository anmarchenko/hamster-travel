defmodule HamsterTravel.Repo.Migrations.AddDestinationDayConstraints do
  use Ecto.Migration

  def up do
    # Add check constraint to ensure start_day <= end_day
    execute "ALTER TABLE destinations ADD CONSTRAINT destinations_start_day_lte_end_day CHECK (start_day <= end_day)"

    # Add check constraint to ensure start_day is non-negative
    execute "ALTER TABLE destinations ADD CONSTRAINT destinations_start_day_non_negative CHECK (start_day >= 0)"

    # Add check constraint to ensure end_day is non-negative
    execute "ALTER TABLE destinations ADD CONSTRAINT destinations_end_day_non_negative CHECK (end_day >= 0)"
  end

  def down do
    # Remove the constraints in reverse order
    execute "ALTER TABLE destinations DROP CONSTRAINT IF EXISTS destinations_end_day_non_negative"

    execute "ALTER TABLE destinations DROP CONSTRAINT IF EXISTS destinations_start_day_non_negative"

    execute "ALTER TABLE destinations DROP CONSTRAINT IF EXISTS destinations_start_day_lte_end_day"
  end
end
