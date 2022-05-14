defmodule HamsterTravelWeb.Planning.IndexDrafts do
  @moduledoc """
  Page showing all the drafts
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Container
  import HamsterTravelWeb.Planning.Grid

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :drafts)
      |> assign(page_title: gettext("Drafts"))
      |> assign(plans: HamsterTravel.drafts())

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
