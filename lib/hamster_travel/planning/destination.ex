defmodule HamsterTravel.Planning.Destination do
  use Ecto.Schema
  import Ecto.Changeset

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
    |> validate_end_day_after_start_day()
  end

  defp validate_end_day_after_start_day(changeset) do
    start_day = get_field(changeset, :start_day)
    end_day = get_field(changeset, :end_day)

    cond do
      is_nil(start_day) or is_nil(end_day) ->
        changeset

      end_day < start_day ->
        add_error(changeset, :end_day, "must be greater than or equal to start_day")

      true ->
        changeset
    end
  end
end
