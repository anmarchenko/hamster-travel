defmodule HamsterTravel.Packing.Backpack.NameSlug do
  use HamsterTravel.EctoNameSlug, module: HamsterTravel.Packing.Backpack
end

defmodule HamsterTravel.Packing.Backpack do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Packing.Backpack.NameSlug

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpacks" do
    field :days, :integer
    field :name, :string
    field :nights, :integer
    field :slug, NameSlug.Type

    field :template, :string, virtual: true

    belongs_to :user, HamsterTravel.Accounts.User
    has_many :lists, HamsterTravel.Packing.List

    timestamps()
  end

  @doc false
  def changeset(backpack, attrs) do
    backpack
    |> cast(attrs, [:name, :days, :nights, :user_id, :template])
    |> validate_required([:name, :days, :nights, :user_id])
    |> validate_number(:days, greater_than: 0)
    |> validate_number(:nights, greater_than_or_equal_to: 0)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end

  def update_changeset(backpack, attrs) do
    backpack
    |> cast(attrs, [:name, :days, :nights])
    |> validate_required([:name, :days, :nights])
    |> validate_number(:days, greater_than: 0)
    |> validate_number(:nights, greater_than_or_equal_to: 0)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
