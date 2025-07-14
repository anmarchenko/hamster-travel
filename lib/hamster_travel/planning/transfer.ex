defmodule HamsterTravel.Planning.Transfer do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Planning.Expense

  @transport_modes ~w(flight train bus car taxi boat)

  schema "transfers" do
    field :day_index, :integer

    field :transport_mode, :string

    field :departure_time, :utc_datetime
    field :arrival_time, :utc_datetime
    field :plus_one_day, :boolean, virtual: true

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
    # First cast to get the plus_one_day field
    temp_changeset =
      transfer
      |> cast(attrs, [:plus_one_day])

    plus_one_day = get_field(temp_changeset, :plus_one_day, false)

    # Pre-process time strings to datetime before main cast
    attrs = convert_time_strings_to_datetime(attrs, plus_one_day)

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
      :day_index,
      :trip_id,
      :departure_city_id,
      :arrival_city_id
    ])
    |> cast_assoc(:expense, with: &Expense.changeset/2)
    |> validate_required([
      :transport_mode,
      :departure_time,
      :arrival_time,
      :day_index,
      :trip_id,
      :departure_city_id,
      :arrival_city_id
    ])
    |> validate_inclusion(:transport_mode, @transport_modes)
    |> validate_number(:day_index, greater_than_or_equal_to: 0)
    |> validate_different_cities()
  end

  # Convert time strings to datetime with anchored date
  defp convert_time_strings_to_datetime(attrs, plus_one_day) do
    attrs
    |> convert_time_field_to_datetime(:departure_time, plus_one_day)
    |> convert_time_field_to_datetime(:arrival_time, plus_one_day)
    |> convert_time_field_to_datetime("departure_time", plus_one_day)
    |> convert_time_field_to_datetime("arrival_time", plus_one_day)
  end

  defp convert_time_field_to_datetime(attrs, field, plus_one_day) do
    case Map.get(attrs, field) do
      nil ->
        attrs

      time_string when is_binary(time_string) ->
        # Normalize time string to include seconds if missing
        normalized_time = normalize_time_string(time_string)

        case Time.from_iso8601(normalized_time) do
          {:ok, time} ->
            # Create datetime with anchored date - use 1970-01-02 if plus_one_day is true
            anchor_date = if plus_one_day, do: ~D[1970-01-02], else: ~D[1970-01-01]
            {:ok, datetime} = DateTime.new(anchor_date, time, "Etc/UTC")
            Map.put(attrs, field, datetime)

          {:error, _} ->
            attrs
        end

      datetime when is_struct(datetime, DateTime) ->
        # Already a datetime, no conversion needed
        attrs

      _ ->
        attrs
    end
  end

  # Normalize time string to include seconds if missing
  defp normalize_time_string(time_string) do
    case String.split(time_string, ":") do
      [hours, minutes] ->
        "#{hours}:#{minutes}:00"

      [hours, minutes, seconds] ->
        "#{hours}:#{minutes}:#{seconds}"

      _ ->
        time_string
    end
  end

  @doc """
  Returns the list of valid transport modes.
  """
  def transport_modes, do: @transport_modes

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
