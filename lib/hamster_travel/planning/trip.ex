defmodule HamsterTravel.Planning.Trip.NameSlug do
  use HamsterTravel.EctoNameSlug, module: HamsterTravel.Planning.Trip
end

defmodule HamsterTravel.Planning.Trip do
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Dates
  alias HamsterTravel.Planning.Accommodation
  alias HamsterTravel.Planning.DayExpense
  alias HamsterTravel.Planning.Destination
  alias HamsterTravel.Planning.Expense
  alias HamsterTravel.Planning.FoodExpense
  alias HamsterTravel.Planning.Note
  alias HamsterTravel.Planning.Transfer
  alias HamsterTravel.Planning.Trip.NameSlug
  alias HamsterTravel.Planning.TripCover
  alias HamsterTravel.Planning.TripParticipant

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @draft "0_draft"
  @planned "1_planned"
  @finished "2_finished"

  @statuses [@draft, @planned, @finished]

  @duration_range 1..30

  schema "trips" do
    field :name, :string
    field :slug, NameSlug.Type

    field :status, :string

    field :dates_unknown, :boolean, default: false
    field :duration, :integer
    field :start_date, :date
    field :end_date, :date

    field :currency, :string
    field :people_count, :integer
    field :private, :boolean, default: false
    field :cover, TripCover.Type
    field :search_text, :string, default: ""

    belongs_to(:author, User)
    has_many(:trip_participants, TripParticipant)
    has_many(:participants, through: [:trip_participants, :user])

    has_many(:destinations, Destination)
    has_many(:cities, through: [:destinations, :city])
    has_many(:countries, through: [:cities, :country])

    has_many(:expenses, Expense)
    has_one(:food_expense, FoodExpense)
    has_many(:accommodations, Accommodation)
    has_many(:transfers, Transfer)
    has_many(:activities, HamsterTravel.Planning.Activity)
    has_many(:day_expenses, DayExpense)
    has_many(:notes, Note)

    timestamps()
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :dates_unknown,
      :start_date,
      :end_date,
      :duration,
      :currency,
      :status,
      :private,
      :people_count,
      :author_id
    ])
    |> cast_attachments(params, [:cover])
    |> validate_required([
      :name,
      :currency,
      :status,
      :author_id,
      :dates_unknown
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:people_count, greater_than: 0)
    |> validate_finished_trip_has_known_dates()
    |> validate_dates_and_duration()
    |> maybe_update_slug()
    |> NameSlug.unique_constraint()
  end

  def statuses do
    @statuses
  end

  def finished do
    @finished
  end

  def planned do
    @planned
  end

  def draft do
    @draft
  end

  defp validate_finished_trip_has_known_dates(changeset) do
    if @finished == get_field(changeset, :status) do
      changeset
      |> validate_change(:dates_unknown, fn :dates_unknown, dates_unknown ->
        validate_dates_unkown(dates_unknown)
      end)
    else
      changeset
    end
  end

  defp validate_dates_and_duration(changeset) do
    dates_unknown = get_field(changeset, :dates_unknown)

    if dates_unknown do
      changeset
      |> validate_required(:duration)
      |> validate_inclusion(:duration, @duration_range, message: "trip duration invalid")
      |> prepare_changes(fn final_changeset ->
        final_changeset
        |> put_change(:start_date, nil)
        |> put_change(:end_date, nil)
      end)
    else
      changeset
      |> validate_required([:start_date, :end_date])
      |> validate_date_range()
      |> prepare_changes(fn final_changeset ->
        final_changeset
        |> put_change(:duration, compute_duration(final_changeset))
      end)
    end
  end

  defp validate_date_range(changeset) do
    if compute_duration(changeset) in @duration_range do
      changeset
    else
      add_error(changeset, :start_date, "trip duration invalid")
    end
  end

  defp validate_dates_unkown(dates_unknown) do
    if dates_unknown do
      [dates_unknown: "dates must be known for a finished trip"]
    else
      []
    end
  end

  defp compute_duration(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    Dates.duration(start_date, end_date)
  end

  defp maybe_update_slug(changeset) do
    if get_change(changeset, :name) do
      NameSlug.force_generate_slug(changeset)
    else
      NameSlug.maybe_generate_slug(changeset)
    end
  end
end
