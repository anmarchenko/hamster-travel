defmodule HamsterTravel.Planning.Destination do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.Validations

  schema "destinations" do
    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    belongs_to(:city, HamsterTravel.Geo.City, type: :id)

    field :start_day, :integer
    field :end_day, :integer

    timestamps()
  end

  @doc false
  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [:start_day, :end_day, :city_id, :trip_id])
    |> validate_required([:start_day, :end_day, :city_id, :trip_id])
    |> validate_number(:start_day, greater_than_or_equal_to: 0)
    |> validate_number(:end_day, greater_than_or_equal_to: 0)
    |> Validations.validate_end_day_after_start_day()
  end
end
