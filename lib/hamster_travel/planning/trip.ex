defmodule HamsterTravel.Planning.Trip.NameSlug do
  use HamsterTravel.EctoNameSlug, module: HamsterTravel.Planning.Trip
end

defmodule HamsterTravel.Planning.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Planning.Trip.NameSlug

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ["0_draft", "1_planned", "2_finished"]
  @finished "2_finished"
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

    belongs_to(:author, User)

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
    |> validate_required([
      :name,
      :currency,
      :status,
      :author_id,
      :dates_unknown
    ])
    |> validate_inclusion(:status, @statuses)
    |> process_dates()
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end

  defp process_dates(%Ecto.Changeset{valid?: true, changes: %{status: @finished}} = changeset),
    do: process_known_dates(changeset)

  defp process_dates(%Ecto.Changeset{valid?: true, data: %{status: @finished}} = changeset),
    do: process_known_dates(changeset)

  defp process_dates(%Ecto.Changeset{valid?: true, changes: %{dates_unknown: false}} = changeset),
    do: process_known_dates(changeset)

  defp process_dates(%Ecto.Changeset{valid?: true, changes: %{dates_unknown: true}} = changeset),
    do: process_unknown_dates(changeset)

  defp process_dates(%Ecto.Changeset{valid?: true, data: %{dates_unknown: false}} = changeset),
    do: process_known_dates(changeset)

  defp process_dates(%Ecto.Changeset{valid?: true, data: %{dates_unknown: true}} = changeset),
    do: process_unknown_dates(changeset)

  defp process_dates(%Ecto.Changeset{valid?: false} = invalid_changeset),
    do: invalid_changeset

  defp process_unknown_dates(changeset) do
    changeset
    |> validate_required(:duration)
    |> validate_inclusion(:duration, @duration_range)
    |> put_change(
      :start_date,
      nil
    )
    |> put_change(
      :end_date,
      nil
    )
  end

  defp process_known_dates(changeset) do
    changeset
    |> validate_required([:start_date, :end_date])
    |> validate_date_range()
    |> put_duration()
    |> put_change(
      :dates_unknown,
      false
    )
  end

  defp validate_date_range(
         %Ecto.Changeset{
           valid?: true,
           changes: %{start_date: start_date, end_date: end_date}
         } = changeset
       ) do
    if compute_duration(start_date, end_date) in @duration_range do
      changeset
    else
      add_error(changeset, :end_date, "trip duration invalid")
    end
  end

  defp validate_date_range(changeset), do: changeset

  defp put_duration(
         %Ecto.Changeset{
           valid?: true,
           changes: %{start_date: start_date, end_date: end_date}
         } = changeset
       ) do
    changeset
    |> put_change(
      :duration,
      compute_duration(start_date, end_date)
    )
  end

  defp put_duration(
         %Ecto.Changeset{
           valid?: true,
           changes: %{start_date: start_date}
         } = changeset
       ) do
    changeset
    |> put_change(
      :duration,
      compute_duration(start_date, changeset.data.end_date)
    )
  end

  defp put_duration(
         %Ecto.Changeset{
           valid?: true,
           changes: %{end_date: end_date}
         } = changeset
       ) do
    changeset
    |> put_change(
      :duration,
      compute_duration(changeset.data.start_date, end_date)
    )
  end

  defp put_duration(changeset) do
    changeset
  end

  defp compute_duration(start_date, end_date), do: Date.diff(end_date, start_date) + 1
end
