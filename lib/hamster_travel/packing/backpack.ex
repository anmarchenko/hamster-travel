defmodule HamsterTravel.Packing.Backpack.NameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug, always_change: true

  import Ecto.Query

  alias HamsterTravel.Packing.Backpack
  alias HamsterTravel.Repo

  def build_slug(sources, changeset) do
    sources |> super(changeset) |> ensure_unique_slug(0)
  end

  defp ensure_unique_slug(slug, attempts) do
    slug_to_try = next_slug(slug, attempts)

    if Repo.exists?(from b in Backpack, where: b.slug == ^slug_to_try) do
      ensure_unique_slug(slug, attempts + 1)
    else
      slug_to_try
    end
  end

  defp next_slug(slug, 0), do: slug
  defp next_slug(slug, attempts), do: "#{slug}-#{attempts}"
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
    field :people, :integer
    field :slug, NameSlug.Type

    field :template, :string, virtual: true

    belongs_to :user, HamsterTravel.Accounts.User
    has_many :lists, HamsterTravel.Packing.List

    timestamps()
  end

  @doc false
  def changeset(backpack, attrs) do
    backpack
    |> cast(attrs, [:name, :days, :people, :user_id, :template])
    |> validate_required([:name, :days, :people, :user_id])
    |> validate_number(:days, greater_than: 0)
    |> validate_number(:people, greater_than: 0)
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
