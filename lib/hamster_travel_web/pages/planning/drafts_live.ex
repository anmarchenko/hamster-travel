defmodule HamsterTravelWeb.Planning.DraftsLive do
  @moduledoc """
  Page showing all the drafts
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravelWeb.Planning.Plan

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    socket =
      socket
      |> assign(active_nav: :drafts)
      |> assign(page_title: gettext("Drafts"))
      |> assign(plans: HamsterTravel.drafts())

    {:noreply, socket}
  end
end
