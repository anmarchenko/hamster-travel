defmodule HamsterTravelWeb.Planning.Tabs do
  @moduledoc """
  Renders plan tabs
  """
  use HamsterTravelWeb, :component

  import PhxComponentHelpers

  import HamsterTravelWeb.Icons.Airplane
  import HamsterTravelWeb.Inline

  @default_class "hidden sm:flex"

  def plan_tabs(assigns) do
    assigns
    |> set_attributes([], required: [:plan, :active_tab])
    |> extend_class(@default_class)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <.tabs underline {@heex_class}>
      <.tab
        underline
        to={plan_url(@plan.slug, :itinerary)}
        is_active={@active_tab == "itinerary"}
        link_type="live_patch"
      >
        <.inline>
          <.airplane />
          <%= gettext("Transfers and hotels") %>
        </.inline>
      </.tab>
      <.tab
        underline
        to={plan_url(@plan.slug, :activities)}
        is_active={@active_tab == "activities"}
        link_type="live_patch"
      >
        <.inline>
          <Heroicons.Outline.clipboard_list />
          <%= gettext("Activities") %>
        </.inline>
      </.tab>
    </.tabs>
    """
  end
end
