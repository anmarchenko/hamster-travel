defmodule HamsterTravel.PackingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Packing` context.
  """

  @doc """
  Generate a backpack.
  """
  def backpack_fixture(attrs \\ %{}) do
    {:ok, backpack} =
      attrs
      |> Enum.into(%{
        days: 42,
        name: "some name",
        people: 42
      })
      |> HamsterTravel.Packing.create_backpack()

    backpack
  end
end
