defmodule HamsterTravel.Planning.Accommodation do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.Validations

  schema "accommodations" do
    field :name, :string
    field :link, :string
    field :address, :string
    field :note, :string
    field :start_day, :integer
    field :end_day, :integer

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    has_one(:expense, HamsterTravel.Planning.Expense)

    timestamps()
  end

  @doc false
  def changeset(accommodation, attrs) do
    accommodation
    |> cast(attrs, [:name, :link, :address, :note, :start_day, :end_day, :trip_id])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([:name, :start_day, :end_day, :trip_id])
    |> validate_number(:start_day, greater_than_or_equal_to: 0)
    |> validate_number(:end_day, greater_than_or_equal_to: 0)
    |> Validations.validate_end_day_after_start_day()
  end
end
