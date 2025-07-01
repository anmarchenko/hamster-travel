defmodule HamsterTravel.Repo.Migrations.AddDayIndexToTransfers do
  use Ecto.Migration

  def change do
    alter table(:transfers) do
      add :day_index, :integer, null: false
    end
  end
end
