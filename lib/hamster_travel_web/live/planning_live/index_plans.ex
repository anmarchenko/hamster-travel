defmodule HamsterTravelWeb.Planning.IndexPlans do
  @moduledoc """
  Page showing all the plans
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Plans"))
      |> stream(:plans, Planning.list_plans(socket.assigns.current_user))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
