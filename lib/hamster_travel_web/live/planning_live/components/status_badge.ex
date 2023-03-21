defmodule HamsterTravelWeb.Planning.StatusBadge do
  @moduledoc """
  Renders badge with plan state (draft/planned/finished)
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def status_badge(assigns) do
    assigns
    |> set_attributes([], required: [:status])
    |> extend_class(&component_class/1, prefix_replace: false)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <span {@heex_class}>
      <%= Gettext.gettext(HamsterTravelWeb.Gettext, @status) %>
    </span>
    """
  end

  defp component_class(assigns) do
    "flex items-center h-6 px-3 text-xs font-semibold rounded-full #{status_colors(assigns)}"
  end

  defp status_colors(%{status: "finished"}),
    do: "text-green-500 bg-green-100 dark:bg-green-800 dark:text-green-100"

  defp status_colors(%{status: "planned"}),
    do: "text-yellow-500 bg-yellow-200 dark:bg-yellow-800 dark:text-yellow-200"

  defp status_colors(%{status: "draft"}),
    do: "text-pink-500 bg-pink-100 dark:bg-pink-800 dark:text-pink-100"
end
