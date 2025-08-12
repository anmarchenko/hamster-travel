defmodule HamsterTravel.Packing do
  @moduledoc """
  The Packing context.
  """

  require Logger

  import Ecto.Query, warn: false
  use Gettext, backend: HamsterTravelWeb.Gettext

  alias HamsterTravel.EctoOrdered
  alias HamsterTravel.Packing.Policy
  alias HamsterTravel.Repo

  alias HamsterTravel.Packing.Backpack
  alias HamsterTravel.Packing.Item
  alias HamsterTravel.Packing.List
  alias HamsterTravel.Packing.Template

  @topic "backpacks"

  # BACKPACK

  def list_backpacks(user) do
    query = from b in Backpack, order_by: [desc: b.inserted_at]

    query
    |> Policy.user_scope(user)
    |> Repo.all()
  end

  def fetch_backpack!(slug, user) do
    query =
      from b in Backpack,
        where: b.slug == ^slug

    query
    |> Policy.user_scope(user)
    |> Repo.one!()
    |> backpack_preloading()
  end

  def get_backpack(id) do
    Backpack
    |> Repo.get(id)
    |> backpack_preloading()
  end

  def get_backpack!(id) do
    Backpack
    |> Repo.get!(id)
    |> backpack_preloading()
  end

  def new_backpack do
    Backpack.changeset(%Backpack{days: 2, nights: 1}, %{})
  end

  def new_backpack(nil) do
    new_backpack()
  end

  def new_backpack(backpack) do
    name = "#{backpack.name} (#{gettext("Copy")})"
    Backpack.changeset(%Backpack{days: backpack.days, nights: backpack.nights, name: name}, %{})
  end

  def backpack_changeset(params) do
    Backpack.changeset(%Backpack{}, params)
  end

  def create_backpack(attrs \\ %{}, user) do
    %Backpack{user_id: user.id}
    |> Backpack.changeset(attrs)
    |> Template.from_changeset()
    |> Repo.insert()
    |> send_telemetry_event([:backpack, :create], %{source: "template"})
  end

  def create_backpack(attrs, user, backpack) do
    %Backpack{user_id: user.id}
    |> Backpack.changeset(attrs)
    |> Ecto.Changeset.put_assoc(
      :lists,
      backpack.lists
      |> Enum.map(fn list ->
        %List{
          name: list.name,
          items:
            list.items
            |> Enum.map(fn item ->
              %Item{
                name: item.name,
                count: item.count
              }
            end)
            |> EctoOrdered.fill_ranks()
        }
      end)
      |> EctoOrdered.fill_ranks()
    )
    |> Repo.insert()
    |> send_telemetry_event([:backpack, :create], %{source: "copy"})
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

  def new_list do
    List.changeset(%List{}, %{})
  end

  def create_list(attrs \\ %{}, %Backpack{} = backpack) do
    %List{backpack_id: backpack.id}
    |> List.changeset(attrs)
    |> Repo.insert()
    |> send_pubsub_event([:list, :created])
  end

  def change_list(%List{} = list) do
    List.update_changeset(list)
  end

  def update_list(%List{} = list, attrs) do
    list
    |> List.update_changeset(attrs)
    |> Repo.update()
    |> send_pubsub_event([:list, :updated])
  end

  def delete_list(%List{} = list) do
    Repo.delete(list)
    |> send_pubsub_event([:list, :deleted])
  end

  def reorder_list(%List{} = list, position) do
    list
    |> List.changeset(%{position: position})
    |> Repo.update()
    |> send_pubsub_event([:list, :moved])
  end

  # ITEMS

  def new_item do
    Item.changeset(%Item{}, %{})
  end

  def format_item(%Item{} = item) do
    item.name <> " " <> Integer.to_string(item.count)
  end

  def create_item(attrs \\ %{}, %List{} = list) do
    processed_attrs = Item.extract_count_from_name(attrs)

    %Item{backpack_list_id: list.id, checked: false}
    |> Item.changeset(processed_attrs)
    |> Repo.insert()
    |> send_pubsub_event([:item, :created])
  end

  def update_item_checked(%Item{} = item, checked) do
    item
    |> Item.checked_changeset(%{checked: checked})
    |> Repo.update()
    |> send_pubsub_event([:item, :updated])
  end

  def update_item(%Item{} = item, attrs) do
    processed_attrs = Item.extract_count_from_name(attrs)

    item
    |> Item.update_changeset(processed_attrs)
    |> Repo.update()
    |> send_pubsub_event([:item, :updated])
  end

  def all_checked?(items) do
    !Enum.empty?(items) && Enum.all?(items, & &1.checked)
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
    |> send_pubsub_event([:item, :deleted])
  end

  def move_item_to_list(%Item{} = item, new_list_id, position) do
    item
    |> Item.changeset(%{backpack_list_id: new_list_id, position: position})
    |> Repo.update()
    |> send_pubsub_event([:item, :moved])
  end

  def reorder_item(%Item{} = item, position) do
    item
    |> Item.changeset(%{position: position})
    |> Repo.update()
    |> send_pubsub_event([:item, :moved])
  end

  def count_backpacks do
    backpacks_count = Repo.aggregate(Backpack, :count, :id)
    :telemetry.execute([:hamster_travel, :packing, :backpacks], %{count: backpacks_count})
    backpacks_count
  end

  defp backpack_preloading(query) do
    items_preload_query = from i in Item, order_by: [i.rank]

    lists_preload_query =
      from l in List, order_by: [l.rank], preload: [items: ^items_preload_query]

    query
    |> Repo.preload(lists: lists_preload_query)
  end

  defp send_pubsub_event({:ok, result} = return_tuple, [:item, _] = event) do
    list_id = result.backpack_list_id

    backpack_id = Repo.one(from(l in List, select: l.backpack_id, where: l.id == ^list_id))

    Phoenix.PubSub.broadcast(
      HamsterTravel.PubSub,
      @topic <> ":#{backpack_id}",
      {event, %{value: result}}
    )

    return_tuple
  end

  defp send_pubsub_event({:ok, result} = return_tuple, [:list, _] = event) do
    backpack_id = result.backpack_id

    Phoenix.PubSub.broadcast(
      HamsterTravel.PubSub,
      @topic <> ":#{backpack_id}",
      {event, %{value: result}}
    )

    return_tuple
  end

  defp send_pubsub_event({:ok, _} = result, _), do: result

  defp send_pubsub_event({:error, reason}, _), do: {:error, reason}

  defp send_telemetry_event({:ok, _} = result, event, metadata) do
    :telemetry.execute([:hamster_travel, :packing] ++ event, %{count: 1}, metadata)

    result
  end

  defp send_telemetry_event(result, _, _), do: result
end
