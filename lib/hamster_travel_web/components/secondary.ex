defmodule HamsterTravelWeb.Secondary do
  @moduledoc """
  Renders secondary content
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def secondary(assigns) do
    assigns
    |> set_attributes([tag: "p", italic: true], required: [:inner_block])
    |> extend_class(&component_class/1, prefix_replace: false)
    |> render()
  end

  defp render(%{tag: "div"} = assigns) do
    ~H"""
    <div {@heex_class}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp render(%{tag: "p"} = assigns) do
    ~H"""
    <p {@heex_class}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  defp component_class(assigns) do
    "text-zinc-400 dark:text-zinc-500 #{italic(assigns)}"
  end

  defp italic(%{italic: true}), do: "italic"
  defp italic(_), do: ""
end
