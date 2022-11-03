defmodule HamsterTravel.Packing.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpack_items" do
    field :checked, :boolean, default: false
    field :count, :integer
    field :name, :string

    belongs_to :backpack_list, HamsterTravel.Packing.List

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :checked, :count, :backpack_list_id])
    |> validate_required([:name, :checked, :count, :backpack_list_id])
  end

  def checked_changeset(item, attrs) do
    item
    |> cast(attrs, [:checked])
    |> validate_required([:checked])
  end
end
