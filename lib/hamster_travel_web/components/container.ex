defmodule HamsterTravelWeb.Container do
  @moduledoc """
  Renders section (aka container)
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def container(assigns) do
    assigns
    |> set_attributes([wide: false], required: [:inner_block])
    |> extend_class(&component_class/1)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <section {@heex_class}>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  defp component_class(assigns) do
    "mx-auto max-w-screen-md #{width(assigns)}"
  end

  defp width(%{wide: true}), do: "xl:max-w-screen-xl 2xl:max-w-screen-2xl"
  defp width(_), do: "xl:max-w-screen-lg 2xl:max-w-screen-xl"
end
