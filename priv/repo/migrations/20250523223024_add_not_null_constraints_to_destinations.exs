defmodule HamsterTravel.Repo.Migrations.AddNotNullConstraintsToDestinations do
  use Ecto.Migration

  def up do
    # Add NOT NULL constraints to destinations table
    alter table(:destinations) do
      modify :start_day, :integer, null: false
      modify :end_day, :integer, null: false
    end
  end

  def down do
    # Remove NOT NULL constraints from destinations table
    alter table(:destinations) do
      modify :start_day, :integer, null: true
      modify :end_day, :integer, null: true
    end
  end
end
