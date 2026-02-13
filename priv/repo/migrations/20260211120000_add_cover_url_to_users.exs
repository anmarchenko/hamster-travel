defmodule HamsterTravel.Repo.Migrations.AddCoverUrlToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :cover_url, :string
    end
  end
end
