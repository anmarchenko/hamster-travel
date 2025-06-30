defmodule HamsterTravel.Repo.Migrations.AddTransferIdToExpenses do
  use Ecto.Migration

  def change do
    alter table(:expenses) do
      add :transfer_id, references(:transfers, on_delete: :delete_all)
    end

    create index(:expenses, [:transfer_id])
  end
end
