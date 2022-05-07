defmodule HamsterTravelWeb.Link do
  @moduledoc """
  Renders link
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  @default_class "underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100"

  def link(assigns) do
    assigns
    |> set_attributes([label: "", inner_block: nil, link_type: "live_redirect"], required: [:to])
    |> extend_class(@default_class)
    |> render()
  end

  defp render(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <%= live_redirect to: @to, class: @class do %>
      <%= if @inner_block, do: render_slot(@inner_block), else: @label %>
    <% end %>
    """
  end

  defp render(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <%= live_patch to: @to, class: @class do %>
      <%= if @inner_block, do: render_slot(@inner_block), else: @label %>
    <% end %>
    """
  end

  defp render(%{link_type: "a"} = assigns) do
    ~H"""
    <a href={@to} target="_blank" rel="noreferer noopener" {@heex_class}>
      <%= if @inner_block, do: render_slot(@inner_block), else: @label %>
    </a>
    """
  end
end
