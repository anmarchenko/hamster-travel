defmodule HamsterTravel.Planning.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "trips" do
    field :currency, :string
    field :dates_unknown, :boolean, default: false
    field :duration, :integer
    field :end_date, :date
    field :name, :string
    field :people_count, :integer
    field :private, :boolean, default: false
    field :start_date, :date
    field :status, :string
    field :author_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [:name, :dates_unknown, :duration, :start_date, :end_date, :currency, :status, :private, :people_count])
    |> validate_required([:name, :dates_unknown, :duration, :start_date, :end_date, :currency, :status, :private, :people_count])
  end
end
