defmodule HamsterTravel.Packing do
  @moduledoc """
  The Packing context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Packing.{Backpack, Template}

  @doc """
  Returns the list of backpacks.

  ## Examples

      iex> list_backpacks()
      [%Backpack{}, ...]

  """
  def list_backpacks(user) do
    query = from b in Backpack, where: b.user_id == ^user.id

    Repo.all(query)
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
  def get_backpack!(id) do
    Backpack
    |> Repo.get!(id)
    |> Repo.preload(lists: :items)
  end

  @doc """
  Gets a single backpack by slug.

  Raises `Ecto.NoResultsError` if the Backpack does not exist.

  ## Examples

      iex> get_backpack_by_slug!(123)
      %Backpack{}

      iex> get_backpack!(456)
      ** (Ecto.NoResultsError)

  """
  def get_backpack_by_slug(slug) do
    Backpack
    |> Repo.get_by(slug: slug)
    |> Repo.preload(lists: :items)
  end

  def new_backpack() do
    Backpack.changeset(%Backpack{days: 1, people: 2}, %{})
  end

  @doc """
  Creates a backpack.

  ## Examples

      iex> create_backpack(%{field: value})
      {:ok, %Backpack{}}

      iex> create_backpack(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_backpack(attrs \\ %{}, user) do
    # 1. validate changeset
    # 2. return if invalid
    # 3. parse template
    # 4. insert with cast_assoc
    %Backpack{user_id: user.id}
    |> Backpack.changeset(attrs)
    |> process_template()
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

  defp process_template(
         %Ecto.Changeset{changes: %{template: template, days: days, people: people}} = changeset
       )
       when template != nil do
    case Template.execute(template, %{days: days, people: people}) do
      {:ok, lists} ->
        changeset
        |> Ecto.Changeset.put_assoc(:lists, lists)

      {:error, messages} ->
        Logger.warn(
          "[HamsterTravel.Packing] Template #{template} could not be parsed. Errors were: #{inspect(messages)} "
        )

        changeset
    end
  end

  defp process_template(changeset), do: changeset
end
