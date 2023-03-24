defmodule HamsterTravelWeb.Planning.Grid do
  @moduledoc """
  Parses plan cards as a grid
  """
  use HamsterTravelWeb, :component

  import HamsterTravelWeb.Planning.PlanCard

  attr(:plans, :list, required: true)

  def grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-8">
      <.plan_card :for={plan <- @plans} plan={plan} />
    </div>
    """
  end
end
