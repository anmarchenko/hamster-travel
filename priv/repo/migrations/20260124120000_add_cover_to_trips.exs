defmodule HamsterTravel.Repo.Migrations.AddCoverToTrips do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :cover, :string
    end
  end
end
