defmodule HamsterTravel.Packing.Item do
  use Ecto.Schema
  import Ecto.Changeset
  import HamsterTravel.EctoOrdered

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "backpack_items" do
    field :checked, :boolean, default: false
    field :count, :integer
    field :name, :string
    field :rank, :integer
    field :position, :any, virtual: true
    field :move, :any, virtual: true

    belongs_to :backpack_list, HamsterTravel.Packing.List

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :checked, :count, :position, :backpack_list_id])
    |> validate_required([:name, :checked, :count, :backpack_list_id])
    |> foreign_key_constraint(:backpack_list_id)
    |> set_order(:position, :rank, :backpack_list_id)
  end

  def checked_changeset(item, attrs) do
    item
    |> cast(attrs, [:checked])
    |> validate_required([:checked])
  end

  def update_changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :count])
    |> validate_required([:name, :count])
  end

  def extract_count_from_name(%{name: _, count: count} = attrs)
      when count != nil do
    attrs
  end

  def extract_count_from_name(%{"name" => _, "count" => count} = attrs)
      when count != nil do
    attrs
  end

  def extract_count_from_name(%{name: name} = attrs)
      when name != nil do
    {name, count} = parse_name(name)

    attrs
    |> Map.put(:count, count)
    |> Map.put(:name, name)
  end

  def extract_count_from_name(%{"name" => name} = attrs)
      when name != nil do
    {name, count} = parse_name(name)

    attrs
    |> Map.put("count", count)
    |> Map.put("name", name)
  end

  def extract_count_from_name(attrs), do: attrs

  defp parse_name(name) do
    name = String.trim(name)

    with name_parts when length(name_parts) > 1 <- String.split(name),
         tail_element when is_binary(tail_element) <- List.last(name_parts),
         {count, _} <- Integer.parse(tail_element) do
      {name |> String.trim_trailing(tail_element) |> String.trim(), count}
    else
      _ ->
        {name, 1}
    end
  end
end
