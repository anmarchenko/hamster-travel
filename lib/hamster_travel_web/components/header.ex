defmodule HamsterTravelWeb.Header do
  @moduledoc """
  Renders h1 page level header
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  @default_class "text-xl lg:text-2xl font-semibold"

  def header(assigns) do
    assigns
    |> set_attributes([], required: [:inner_block])
    |> extend_class(@default_class)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <h1
      {@heex_class}
    >
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end
end
