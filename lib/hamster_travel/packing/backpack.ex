defmodule HamsterTravel.Packing.Backpack do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpacks" do
    field :days, :integer
    field :name, :string
    field :people, :integer

    belongs_to :user, HamsterTravel.Accounts.User
    has_many :lists, HamsterTravel.Packing.List

    timestamps()
  end

  @doc false
  def changeset(backpack, attrs) do
    backpack
    |> cast(attrs, [:name, :days, :people, :user_id])
    |> validate_required([:name, :days, :people, :user_id])
    |> validate_number(:days, greater_than: 0)
    |> validate_number(:people, greater_than: 0)
  end
end
