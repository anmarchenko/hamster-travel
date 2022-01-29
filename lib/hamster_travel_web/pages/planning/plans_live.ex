defmodule HamsterTravelWeb.Planning.PlansLive do
  @moduledoc """
  Page showing all the plans
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravelWeb.Planning.PlansList

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :plans)
      |> assign(page_title: gettext("Plans"))
      |> assign(plans: HamsterTravel.plans())

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
