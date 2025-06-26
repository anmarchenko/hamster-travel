defmodule HamsterTravel.Repo.Migrations.AlterAccommodationsLinkAddressToText do
  use Ecto.Migration

  def change do
    alter table(:accommodations) do
      modify :link, :text
      modify :address, :text
    end
  end
end
