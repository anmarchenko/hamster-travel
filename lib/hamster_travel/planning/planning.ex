defmodule HamsterTravel.Planning do
  @moduledoc """
  The Planning context.
  """

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Planning.Policy
  alias HamsterTravel.Planning.Trip

  @doc """
  Returns the list of trips.

  ## Examples

      iex> list_trips()
      [%Trip{}, ...]

  """
  def list_trips(user) do
    query = from t in Trip, order_by: [desc: t.inserted_at]

    query
    |> Policy.user_scope(user)
    |> Repo.all()
  end

  def get_trip(id), do: Repo.get(Trip, id)

  @doc """
  Gets a single trip.

  Raises `Ecto.NoResultsError` if the Trip does not exist.

  ## Examples

      iex> get_trip!(123)
      %Trip{}

      iex> get_trip!(456)
      ** (Ecto.NoResultsError)

  """
  def get_trip!(id), do: Repo.get!(Trip, id)

  def get_user_trip_by_slug(slug, user) do
    query =
      from t in Trip,
        where: t.slug == ^slug

    query
    |> Policy.user_scope(user)
    |> Repo.one()
  end

  def trip_changeset(params) do
    Trip.changeset(%Trip{}, params)
  end

  def new_trip do
    Trip.changeset(
      %Trip{status: Trip.draft(), people_count: 2, private: false, currency: "EUR"},
      %{}
    )
  end

  @doc """
  Creates a trip.

  ## Examples

      iex> create_trip(%{field: value})
      {:ok, %Trip{}}

      iex> create_trip(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_trip(attrs \\ %{}, user) do
    %Trip{author_id: user.id}
    |> Trip.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trip.

  ## Examples

      iex> update_trip(trip, %{field: new_value})
      {:ok, %Trip{}}

      iex> update_trip(trip, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_trip(%Trip{} = trip, attrs) do
    trip
    |> Trip.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trip.

  ## Examples

      iex> delete_trip(trip)
      {:ok, %Trip{}}

      iex> delete_trip(trip)
      {:error, %Ecto.Changeset{}}

  """
  def delete_trip(%Trip{} = trip) do
    Repo.delete(trip)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trip changes.

  ## Examples

      iex> change_trip(trip)
      %Ecto.Changeset{data: %Trip{}}

  """
  def change_trip(%Trip{} = trip, attrs \\ %{}) do
    Trip.changeset(trip, attrs)
  end
end
