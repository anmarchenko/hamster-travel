defmodule HamsterTravel.Collections do
  @moduledoc """
  Utilities to work with enums
  """

  def replace(collection, predicate, generator) do
    collection
    |> Enum.map(fn item ->
      if predicate.(item) do
        generator.(item)
      else
        item
      end
    end)
    |> Enum.filter(fn item -> item != nil end)
  end
end
