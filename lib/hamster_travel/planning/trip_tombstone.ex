defmodule HamsterTravel.Planning.TripTombstone do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "trips_tombstones" do
    field :original_slug, :string
    field :payload, :map
    field :payload_version, :integer, default: 1

    belongs_to :author, HamsterTravel.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(tombstone, attrs) do
    tombstone
    |> cast(attrs, [:original_slug, :author_id, :payload, :payload_version])
    |> validate_required([:original_slug, :author_id, :payload, :payload_version])
  end
end
