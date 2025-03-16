defmodule HamsterTravelWeb.Planning.DayRangeSelect do
  use HamsterTravelWeb, :live_component

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.label for={@field.id}>{@label}</.label>
    </div>
    """
  end
end
