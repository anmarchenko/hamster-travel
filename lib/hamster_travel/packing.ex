defmodule HamsterTravel.Packing do
  @moduledoc """
  The Packing context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias HamsterTravel.Repo

  alias HamsterTravel.Packing.Backpack
  alias HamsterTravel.Packing.Item
  alias HamsterTravel.Packing.List
  alias HamsterTravel.Packing.Template

  @topic "backpacks"

  # BACKPACK

  def list_backpacks(user) do
    query = from b in Backpack, where: b.user_id == ^user.id, order_by: [desc: b.inserted_at]

    Repo.all(query)
  end

  def get_backpack!(id) do
    Backpack
    |> Repo.get!(id)
    |> backpack_preloading()
  end

  def get_backpack_by_slug(slug, user) do
    Backpack
    |> Repo.get_by(slug: slug, user_id: user.id)
    |> backpack_preloading()
  end

  def new_backpack do
    Backpack.changeset(%Backpack{days: 2, nights: 1}, %{})
  end

  def create_backpack(attrs \\ %{}, user) do
    %Backpack{user_id: user.id}
    |> Backpack.changeset(attrs)
    |> Template.from_changeset()
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

  # LISTS

  def create_list(attrs \\ %{}, %Backpack{} = backpack) do
    %List{backpack_id: backpack.id}
    |> List.changeset(attrs)
    |> Repo.insert()
  end

  # ITEMS

  def new_item do
    Item.changeset(%Item{}, %{})
  end

  def create_item(attrs \\ %{}, %List{} = list) do
    processed_attrs = Item.extract_count_from_name(attrs)

    %Item{backpack_list_id: list.id, checked: false}
    |> Item.changeset(processed_attrs)
    |> Repo.insert()
    |> notify_event([:item, :created])
  end

  def update_item_checked(%Item{} = item, checked) do
    item
    |> Item.checked_changeset(%{checked: checked})
    |> Repo.update()
    |> notify_event([:item, :updated])
  end

  defp backpack_preloading(query) do
    items_preload_query = from i in Item, order_by: [i.inserted_at, i.id]

    lists_preload_query =
      from l in List, order_by: [l.inserted_at, l.id], preload: [items: ^items_preload_query]

    query
    |> Repo.preload(lists: lists_preload_query)
  end

  defp notify_event({:ok, result}, [:item, _] = event) do
    list_id = result.backpack_list_id

    backpack_id = Repo.one(from(l in List, select: l.backpack_id, where: l.id == ^list_id))

    Phoenix.PubSub.broadcast(
      HamsterTravel.PubSub,
      @topic <> ":#{backpack_id}",
      {event, %{item: result}}
    )

    {:ok, result}
  end

  defp notify_event({:ok, result}, _) do
    {:ok, result}
  end

  defp notify_event({:error, reason}, _), do: {:error, reason}
end
