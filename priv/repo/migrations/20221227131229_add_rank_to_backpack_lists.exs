defmodule HamsterTravel.Repo.Migrations.AddRankToBackpackLists do
  use Ecto.Migration

  def change do
    alter table("backpack_lists") do
      add :rank, :integer, null: false
    end
  end
end
