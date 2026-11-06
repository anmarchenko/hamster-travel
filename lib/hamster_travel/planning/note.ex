defmodule HamsterTravel.Planning.Note do
  use Ecto.Schema
  import Ecto.Changeset
  import HamsterTravel.EctoOrdered

  schema "notes" do
    field :title, :string
    field :text, :string
    field :rank, :integer
    field :position, :any, virtual: true

    belongs_to(:trip, HamsterTravel.Planning.Trip, type: :binary_id)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :text, :trip_id, :position])
    |> validate_required([:title, :trip_id])
    |> set_order(:position, :rank, :trip_id)
  end
end
