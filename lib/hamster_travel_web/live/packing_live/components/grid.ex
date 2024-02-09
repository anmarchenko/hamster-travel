defmodule HamsterTravelWeb.Packing.Grid do
  @moduledoc """
  Parses plan cards as a grid
  """
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Packing.Backpacks.Card

  attr(:backpacks, :list, required: true)

  def grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
      <.backpack_card :for={backpack <- @backpacks} backpack={backpack} />
    </div>
    """
  end
end
