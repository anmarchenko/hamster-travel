defmodule HamsterTravelWeb.Container do
  @moduledoc """
  Renders section (aka container)
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def container(assigns) do
    assigns
    |> set_attributes([wide: false, form: false, nomargin: false], required: [:inner_block])
    |> extend_class(&component_class/1, prefix_replace: false)
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
    "mx-auto max-w-screen-md #{margins(assigns)} #{width(assigns)}"
  end

  defp margins(%{nomargin: true}), do: ""
  defp margins(_), do: "p-6 mt-6"

  defp width(%{wide: true}), do: "xl:max-w-screen-xl 2xl:max-w-screen-2xl"
  defp width(%{form: true}), do: "max-w-screen-md"
  defp width(_), do: "xl:max-w-screen-lg 2xl:max-w-screen-xl"
end
