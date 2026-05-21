defmodule HamsterTravel.Repo.Migrations.AddLinkToDayExpenses do
  use Ecto.Migration

  def change do
    alter table(:day_expenses) do
      add :link, :text
    end
  end
end
