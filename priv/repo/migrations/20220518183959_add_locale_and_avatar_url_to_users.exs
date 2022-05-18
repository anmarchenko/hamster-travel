defmodule HamsterTravel.Repo.Migrations.AddLocaleAndAvatarUrlToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :locale, :string, null: false, default: "en"
      add :avatar_url, :string
    end
  end
end
