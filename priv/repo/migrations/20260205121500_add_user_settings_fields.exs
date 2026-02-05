defmodule HamsterTravel.Repo.Migrations.AddUserSettingsFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :default_currency, :string
      add :home_city_id, references(:cities)
    end

    create index(:users, [:home_city_id])
  end
end
