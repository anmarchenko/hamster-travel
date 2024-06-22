defmodule HamsterTravelWeb.Planning.IndexDrafts do
  @moduledoc """
  Page showing all the drafts
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.Grid

  alias HamsterTravel.Planning

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: drafts_nav_item())
      |> assign(page_title: gettext("Drafts"))
      |> stream(:plans, Planning.list_drafts(socket.assigns.current_user))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
