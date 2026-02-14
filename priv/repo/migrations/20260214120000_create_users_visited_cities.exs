defmodule HamsterTravel.Repo.Migrations.CreateUsersVisitedCities do
  use Ecto.Migration

  def change do
    create table(:users_visited_cities) do
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :city_id, references(:cities, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:users_visited_cities, [:user_id])
    create index(:users_visited_cities, [:city_id])
    create unique_index(:users_visited_cities, [:user_id, :city_id])
  end
end
