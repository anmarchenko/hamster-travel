defmodule HamsterTravelWeb.Planning.PlacesList do
  @moduledoc """
  Renders list of places live components
  """
  use HamsterTravelWeb, :component

  import PhxComponentHelpers

  alias HamsterTravelWeb.Planning.Place

  def places_list(assigns) do
    assigns
    |> set_attributes([], required: [:places, :day_index])
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <%= for place <- @places do %>
      <.live_component
        module={Place}
        id={"places-#{place.id}-day-#{@day_index}"}
        place={place}
        day_index={@day_index}
      />
    <% end %>
    """
  end
end
