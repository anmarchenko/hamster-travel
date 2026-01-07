defmodule HamsterTravel.Planning.Note do
  use Ecto.Schema
  import Ecto.Changeset
  import HamsterTravel.EctoOrdered

  schema "notes" do
    field :title, :string
    field :text, :string
    field :day_index, :integer
    field :rank, :integer
    field :position, :any, virtual: true

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :text, :day_index, :trip_id, :position])
    |> validate_required([:title, :trip_id])
    |> validate_day_index()
    |> set_order(:position, :rank, [:trip_id, :day_index])
  end

  defp validate_day_index(changeset) do
    case get_field(changeset, :day_index) do
      nil -> changeset
      _ -> validate_number(changeset, :day_index, greater_than_or_equal_to: 0)
    end
  end
end
