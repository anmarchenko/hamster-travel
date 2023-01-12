defmodule HamsterTravel.Repo.Migrations.AddRankToBackpackItems do
  use Ecto.Migration

  def change do
    alter table("backpack_items") do
      add :rank, :integer, null: false
    end
  end
end
