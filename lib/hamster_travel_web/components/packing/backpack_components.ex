defmodule HamsterTravelWeb.Packing.BackpackComponents do
  @moduledoc """
  Common components for backpacks
  """
  use HamsterTravelWeb, :component

  def backpack_url(slug), do: "/backpacks/#{slug}"
  def backpack_url(slug, :edit), do: "/backpacks/#{slug}/edit"
  def backpack_url(slug, :delete), do: "/backpacks/#{slug}/delete"
end
