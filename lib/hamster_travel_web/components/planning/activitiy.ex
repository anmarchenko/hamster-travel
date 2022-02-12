defmodule HamsterTravelWeb.Planning.Activity do
  @moduledoc """
  Live component responsible for showing and editing activities
  """
  use HamsterTravelWeb, :live_component

  def update(%{activity: activity, index: index}, socket) do
    socket =
      socket
      |> assign(activity: activity)
      |> assign(index: index)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    Edit is not implemented yet
    """
  end

  def render(%{edit: false, activity: activity, index: index} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-2">
      <div>
        <%= "#{index+1}." %>
        <%= activity.name %>
      </div>
    </div>
    """
  end
end
