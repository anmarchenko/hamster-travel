defmodule HamsterTravelWeb.Packing.BackpackComponents do
  @moduledoc """
  Common components for backpacks
  """
  use HamsterTravelWeb, :component

  def backpack_url(slug), do: "/backpacks/#{slug}"
end
