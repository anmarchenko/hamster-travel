defmodule HamsterTravel.Packing.Backpack do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpacks" do
    field :days, :integer
    field :name, :string
    field :people, :integer
    field :user, :binary_id

    timestamps()
  end

  @doc false
  def changeset(backpack, attrs) do
    backpack
    |> cast(attrs, [:name, :days, :people])
    |> validate_required([:name, :days, :people])
  end
end
