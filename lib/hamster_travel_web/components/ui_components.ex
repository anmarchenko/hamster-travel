defmodule HamsterTravelWeb.UIComponents do
  @moduledoc """
  Common phoenix components
  """
  use HamsterTravelWeb, :component

  def icon_text(assigns) do
    ~H"""
      <div class="flex flex-row gap-x-2 items-center">
        <%= render_slot(@inner_block) %>
      </div>
    """
  end
end
