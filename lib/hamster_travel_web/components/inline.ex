defmodule HamsterTravelWeb.Inline do
  @moduledoc """
  Renders a set of child items inline with gaps between them
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def inline(assigns) do
    assigns
    |> set_attributes([wrap: false], required: [:inner_block])
    |> extend_class(&component_class/1)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <div {@heex_class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp component_class(assigns) do
    "flex flex-row gap-2 items-center block #{wrap(assigns)}"
  end

  defp wrap(%{wrap: true}), do: "flex-wrap"
  defp wrap(_), do: ""
end
