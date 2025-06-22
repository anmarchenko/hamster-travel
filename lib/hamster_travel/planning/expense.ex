defmodule HamsterTravel.Planning.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenses" do
    field :price, Money.Ecto.Composite.Type
    field :name, :string

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    belongs_to(:accommodation, HamsterTravel.Planning.Accommodation)

    timestamps()
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:price, :name, :trip_id, :accommodation_id])
    |> validate_required([:price, :trip_id])
  end
end
