defmodule HamsterTravel.Planning.Transfer do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.Expense

  @transport_modes ~w(flight train bus car taxi boat)

  schema "transfers" do
    field :transport_mode, :string
    field :departure_time, :utc_datetime
    field :arrival_time, :utc_datetime
    field :note, :string
    field :vessel_number, :string
    field :carrier, :string
    field :departure_station, :string
    field :arrival_station, :string

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)
    belongs_to(:departure_city, HamsterTravel.Geo.City, type: :id)
    belongs_to(:arrival_city, HamsterTravel.Geo.City, type: :id)
    has_one(:expense, HamsterTravel.Planning.Expense)

    timestamps()
  end

  @doc false
  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [
      :transport_mode,
      :departure_time,
      :arrival_time,
      :note,
      :vessel_number,
      :carrier,
      :departure_station,
      :arrival_station,
      :trip_id,
      :departure_city_id,
      :arrival_city_id
    ])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([
      :transport_mode,
      :departure_time,
      :arrival_time,
      :trip_id,
      :departure_city_id,
      :arrival_city_id
    ])
    |> validate_inclusion(:transport_mode, @transport_modes)
    |> validate_arrival_after_departure()
    |> validate_different_cities()
  end

  @doc """
  Returns the list of valid transport modes.
  """
  def transport_modes, do: @transport_modes

  defp validate_arrival_after_departure(changeset) do
    departure_time = get_field(changeset, :departure_time)
    arrival_time = get_field(changeset, :arrival_time)

    cond do
      is_nil(departure_time) or is_nil(arrival_time) ->
        changeset

      DateTime.compare(arrival_time, departure_time) in [:lt, :eq] ->
        add_error(changeset, :arrival_time, "must be after departure time")

      true ->
        changeset
    end
  end

  defp validate_different_cities(changeset) do
    departure_city_id = get_field(changeset, :departure_city_id)
    arrival_city_id = get_field(changeset, :arrival_city_id)

    cond do
      is_nil(departure_city_id) or is_nil(arrival_city_id) ->
        changeset

      departure_city_id == arrival_city_id ->
        add_error(changeset, :arrival_city_id, "must be different from departure city")

      true ->
        changeset
    end
  end
end
