defmodule HamsterTravelWeb.Inline do
  @moduledoc """
  Renders a set of child items inline with gaps between them
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  @default_class "inline-flex gap-2 items-center block"

  def inline(assigns) do
    assigns
    |> set_attributes([], required: [:inner_block])
    |> extend_class(@default_class)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <div {@heex_class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
