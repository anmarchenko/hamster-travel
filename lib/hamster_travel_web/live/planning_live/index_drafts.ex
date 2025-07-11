defmodule HamsterTravelWeb.Planning.IndexDrafts do
  @moduledoc """
  Page showing all the drafts
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning

  @impl true
  def render(assigns) do
    ~H"""
    <.container wide>
      <div class="mb-8">
        <.button :if={@current_user} link_type="live_redirect" to="trips/new?draft=1" color="primary">
          <.icon name="hero-plus-solid" class="w-5 h-5 mr-2" />
          {gettext("Create draft")}
        </.button>
      </div>
      <.trips_grid trips={@streams.plans} display_currency={@display_currency} />
    </.container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: drafts_nav_item())
      |> assign(page_title: gettext("Drafts"))
      # get the display currency from the user
      |> assign(display_currency: "EUR")
      |> stream(:plans, Planning.list_drafts(socket.assigns.current_user))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
