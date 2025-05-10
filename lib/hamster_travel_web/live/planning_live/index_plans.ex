defmodule HamsterTravelWeb.Planning.IndexPlans do
  @moduledoc """
  Page showing all the plans
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning

  @impl true
  def render(assigns) do
    ~H"""
    <.container wide>
      <div class="mb-8">
        <.button :if={@current_user} link_type="live_redirect" to="trips/new" color="primary">
          <.icon name="hero-plus-solid" class="w-5 h-5 mr-2" />
          {gettext("Create trip")}
        </.button>
      </div>
      <.trips_grid trips={@streams.plans} />
    </.container>
    """
  end

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
