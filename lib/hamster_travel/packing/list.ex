defmodule HamsterTravel.Packing.List do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpack_lists" do
    field :name, :string

    belongs_to :backpack, HamsterTravel.Packing.Backpack

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:name, :backpack_id])
    |> validate_required([:name, :backpack_id])
  end
end
