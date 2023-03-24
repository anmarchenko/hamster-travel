defmodule HamsterTravelWeb.Planning.PlacesList do
  @moduledoc """
  Renders list of places live components
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.Planning.Place

  attr(:places, :list, required: true)
  attr(:day_index, :integer, required: true)

  def places_list(assigns) do
    ~H"""
    <.live_component
      :for={place <- @places}
      module={Place}
      id={"places-#{place.id}-day-#{@day_index}"}
      place={place}
      day_index={@day_index}
    />
    """
  end
end
