defmodule HamsterTravel.Planning.Activity do
  use Ecto.Schema
  import Ecto.Changeset
  import HamsterTravel.EctoOrdered

  alias HamsterTravel.Planning.Expense

  schema "activities" do
    field :name, :string
    field :day_index, :integer
    field :priority, :integer
    field :link, :string
    field :address, :string
    field :description, :string
    field :rank, :integer
    field :position, :any, virtual: true

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    has_one(:expense, HamsterTravel.Planning.Expense)

    timestamps()
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [
      :name,
      :day_index,
      :priority,
      :link,
      :address,
      :description,
      :trip_id,
      :position
    ])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([:name, :day_index, :priority, :trip_id])
    |> validate_number(:day_index, greater_than_or_equal_to: 0)
    |> validate_inclusion(:priority, 1..3)
    |> set_order(:position, :rank, [:trip_id, :day_index])
  end
end
