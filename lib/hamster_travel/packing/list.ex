defmodule HamsterTravel.Packing.List do
  use Ecto.Schema
  import Ecto.Changeset
  import HamsterTravel.EctoOrdered

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpack_lists" do
    field :name, :string
    field :rank, :integer
    field :position, :any, virtual: true
    field :move, :any, virtual: true

    belongs_to :backpack, HamsterTravel.Packing.Backpack
    has_many :items, HamsterTravel.Packing.Item, foreign_key: :backpack_list_id

    timestamps()
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:name, :backpack_id, :position])
    |> validate_required([:name, :backpack_id])
    |> set_order(:position, :rank, :backpack_id)
  end

  def update_changeset(list, attrs \\ %{}) do
    list
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
