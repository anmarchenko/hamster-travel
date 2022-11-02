defmodule HamsterTravelWeb.Link do
  @moduledoc """
  Renders link
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  @default_class "underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100"

  def a(assigns) do
    assigns
    |> set_attributes([label: "", inner_block: nil, link_type: "live_redirect", method: :get],
      required: [:to]
    )
    |> extend_class(@default_class, prefix_replace: false)
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
    <a href={@to} target="_blank" rel="noreferer noopener" {@heex_class} {@heex_phx_attributes}>
      <%= if @inner_block, do: render_slot(@inner_block), else: @label %>
    </a>
    """
  end

  defp render(%{link_type: "link"} = assigns) do
    ~H"""
    <%= link(@label, to: @to, method: @method, class: @class) %>
    """
  end
end
