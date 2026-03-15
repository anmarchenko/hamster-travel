defmodule HamsterTravel.Repo.Migrations.WidenLinkAndUrlColumnsToText do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      modify :link, :text, from: :string
    end

    alter table(:users) do
      modify :avatar_url, :text, from: :string
      modify :cover_url, :text, from: :string
    end
  end
end
