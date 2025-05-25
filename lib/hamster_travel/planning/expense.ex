defmodule HamsterTravel.Planning.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenses" do
    field :price, Money.Ecto.Composite.Type
    field :name, :string

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:price, :name, :trip_id])
    |> validate_required([:price, :trip_id])
  end
end
