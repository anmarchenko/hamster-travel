defmodule HamsterTravelWeb.Planning.Grid do
  @moduledoc """
  Parses and renders an external link
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.Planning.PlanCard

  def grid(assigns) do
    assigns
    |> set_attributes([], required: [:plans])
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 xl:grid-cols-2 2xl:grid-cols-3 gap-8">
      <%= for plan <- @plans do %>
        <.plan_card plan={plan} />
      <% end %>
    </div>
    """
  end
end
