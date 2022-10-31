defmodule HamsterTravel.Packing do
  @moduledoc """
  The Packing context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Packing.{Backpack, Template}

  def list_backpacks(user) do
    query = from b in Backpack, where: b.user_id == ^user.id, order_by: [desc: b.inserted_at]

    Repo.all(query)
  end

  def get_backpack!(id) do
    Backpack
    |> Repo.get!(id)
    |> Repo.preload(lists: :items)
  end

  def get_backpack_by_slug(slug, user) do
    Backpack
    |> Repo.get_by(slug: slug, user_id: user.id)
    |> Repo.preload(lists: :items)
  end

  def new_backpack do
    Backpack.changeset(%Backpack{days: 2, nights: 1}, %{})
  end

  def create_backpack(attrs \\ %{}, user) do
    %Backpack{user_id: user.id}
    |> Backpack.changeset(attrs)
    |> process_template()
    |> Repo.insert()
  end

  def change_backpack(%Backpack{} = backpack, attrs \\ %{}) do
    Backpack.update_changeset(backpack, attrs)
  end

  def update_backpack(%Backpack{} = backpack, attrs) do
    backpack
    |> Backpack.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_backpack(%Backpack{} = backpack) do
    Repo.delete(backpack)
  end

  defp process_template(
         %Ecto.Changeset{changes: %{template: template, days: days, nights: nights}} = changeset
       )
       when template != nil do
    case Template.execute(template, %{days: days, nights: nights}) do
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
