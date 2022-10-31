defmodule HamsterTravel.Repo.Migrations.RenamePeopleToNightsForBackpacks do
  use Ecto.Migration

  def change do
    rename table(:backpacks), :people, to: :nights
  end
end
