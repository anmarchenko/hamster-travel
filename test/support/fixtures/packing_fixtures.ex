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
end
