defmodule HamsterTravel.Packing do
  @moduledoc """
  The Packing context.
  """

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Packing.Backpack

  @doc """
  Returns the list of backpacks.

  ## Examples

      iex> list_backpacks()
      [%Backpack{}, ...]

  """
  def list_backpacks do
    Repo.all(Backpack)
  end

  @doc """
  Gets a single backpack.

  Raises `Ecto.NoResultsError` if the Backpack does not exist.

  ## Examples

      iex> get_backpack!("32432-fdfgfd43")
      %Backpack{}

      iex> get_backpack!("fdfdfgfd-4343-fgdgfd-543")
      ** (Ecto.NoResultsError)

  """
  def get_backpack!(id), do: Repo.get!(Backpack, id)

  @doc """
  Gets a single backpack by slug.

  Raises `Ecto.NoResultsError` if the Backpack does not exist.

  ## Examples

      iex> get_backpack_by_slug!(123)
      %Backpack{}

      iex> get_backpack!(456)
      ** (Ecto.NoResultsError)

  """
  def get_backpack_by_slug!(slug), do: Repo.get_by!(Backpack, slug: slug)

  @doc """
  Creates a backpack.

  ## Examples

      iex> create_backpack(%{field: value})
      {:ok, %Backpack{}}

      iex> create_backpack(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_backpack(attrs \\ %{}) do
    %Backpack{}
    |> Backpack.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a backpack.

  ## Examples

      iex> update_backpack(backpack, %{field: new_value})
      {:ok, %Backpack{}}

      iex> update_backpack(backpack, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_backpack(%Backpack{} = backpack, attrs) do
    backpack
    |> Backpack.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a backpack.

  ## Examples

      iex> delete_backpack(backpack)
      {:ok, %Backpack{}}

      iex> delete_backpack(backpack)
      {:error, %Ecto.Changeset{}}

  """
  def delete_backpack(%Backpack{} = backpack) do
    Repo.delete(backpack)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking backpack changes.

  ## Examples

      iex> change_backpack(backpack)
      %Ecto.Changeset{data: %Backpack{}}

  """
  def change_backpack(%Backpack{} = backpack, attrs \\ %{}) do
    Backpack.changeset(backpack, attrs)
  end
end
