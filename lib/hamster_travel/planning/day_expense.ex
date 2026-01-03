defmodule HamsterTravel.Planning.DayExpense do
  use Ecto.Schema
  import Ecto.Changeset
  import HamsterTravel.EctoOrdered

  alias HamsterTravel.Planning.Expense

  schema "day_expenses" do
    field :name, :string
    field :day_index, :integer
    field :rank, :integer
    field :position, :any, virtual: true

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    has_one(:expense, HamsterTravel.Planning.Expense)

    timestamps()
  end

  @doc false
  def changeset(day_expense, attrs) do
    day_expense
    |> cast(attrs, [:name, :day_index, :trip_id, :position])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([:name, :day_index, :trip_id])
    |> validate_number(:day_index, greater_than_or_equal_to: 0)
    |> set_order(:position, :rank, [:trip_id, :day_index])
  end
end
