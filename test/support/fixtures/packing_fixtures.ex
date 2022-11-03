defmodule HamsterTravel.PackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Packing` context.
  """

  @doc """
  Generate a backpack.
  """
  def backpack_fixture(attrs \\ %{}) do
    user = HamsterTravel.AccountsFixtures.user_fixture()

    {:ok, backpack} =
      attrs
      |> Enum.into(%{
        days: 42,
        name: "some name",
        nights: 41
      })
      |> HamsterTravel.Packing.create_backpack(user)

    backpack
  end

  def list_fixture(attrs \\ %{}) do
    backpack = backpack_fixture()

    {:ok, list} =
      attrs
      |> Enum.into(%{
        name: "list name"
      })
      |> HamsterTravel.Packing.create_list(backpack)

    list
  end

  def item_fixture(attrs \\ %{}) do
    list = list_fixture()

    {:ok, item} =
      attrs
      |> Enum.into(%{
        name: "toothbrushes",
        count: 2
      })
      |> HamsterTravel.Packing.create_item(list)

    item
  end
end
