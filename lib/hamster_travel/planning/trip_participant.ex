defmodule HamsterTravel.Planning.TripParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Planning.Trip

  @type t :: %__MODULE__{}

  schema "trip_participants" do
    belongs_to :trip, Trip, type: :binary_id
    belongs_to :user, User, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(trip_participant, attrs) do
    trip_participant
    |> cast(attrs, [:trip_id, :user_id])
    |> validate_required([:trip_id, :user_id])
    |> foreign_key_constraint(:trip_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:trip_id, :user_id],
      name: :trip_participants_trip_id_user_id_index,
      message: "has already been added to this trip"
    )
  end
end
