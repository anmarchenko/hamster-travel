defmodule HamsterTravel.Repo.Migrations.AddAccommodationIdToExpenses do
  use Ecto.Migration

  def change do
    alter table(:expenses) do
      add :accommodation_id, references(:accommodations, on_delete: :delete_all)
    end

    create index(:expenses, [:accommodation_id])
  end
end
