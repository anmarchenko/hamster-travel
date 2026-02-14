defmodule HamsterTravel.Accounts.VisitedCity do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users_visited_cities" do
    belongs_to :user, HamsterTravel.Accounts.User, type: :binary_id
    belongs_to :city, HamsterTravel.Geo.City, type: :id

    timestamps()
  end

  @doc false
  def changeset(visited_city, attrs) do
    visited_city
    |> cast(attrs, [:user_id, :city_id])
    |> validate_required([:user_id, :city_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:city_id)
    |> unique_constraint([:user_id, :city_id],
      name: :users_visited_cities_user_id_city_id_index,
      message: "has already been added"
    )
  end
end
