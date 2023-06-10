defmodule HamsterTravelWeb.Planning.Tabs do
  @moduledoc """
  Renders plan tabs
  """
  use HamsterTravelWeb, :html

  alias HamsterTravelWeb.CoreComponents

  import HamsterTravelWeb.Icons.Airplane

  attr(:plan, :map, required: true)
  attr(:active_tab, :string, required: true)
  attr(:class, :string, default: nil)

  def plan_tabs(assigns) do
    ~H"""
    <.tabs
      underline
      class={
        CoreComponents.build_class([
          "hidden sm:flex",
          @class
        ])
      }
    >
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
          <.icon name={:clipboard_document_list} outline={true} class="h-5 w-5" />
          <%= gettext("Activities") %>
        </.inline>
      </.tab>
    </.tabs>
    """
  end
end
