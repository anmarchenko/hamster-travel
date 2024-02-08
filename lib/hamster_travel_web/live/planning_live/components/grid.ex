defmodule HamsterTravelWeb.Planning.Grid do
  @moduledoc """
  Parses plan cards as a grid
  """
  use HamsterTravelWeb, :html

  import HamsterTravelWeb.Planning.Trips.Card

  attr(:trips, :list, required: true)

  def grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-8">
      <.trip_card :for={trip <- @trips} trip={trip} />
    </div>
    """
  end
end
