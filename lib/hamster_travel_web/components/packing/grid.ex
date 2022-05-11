defmodule HamsterTravelWeb.Packing.Grid do
  @moduledoc """
  Parses plan cards as a grid
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.Packing.BackpackCard

  def grid(assigns) do
    assigns
    |> set_attributes([], required: [:backpacks])
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
      <%= for backpack <- @backpacks do %>
        <.backpack_card backpack={backpack} />
      <% end %>
    </div>
    """
  end
end
