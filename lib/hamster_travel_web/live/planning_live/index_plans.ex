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
      <.trips_empty_state
        :if={@empty_state?}
        title={gettext("No adventures yet")}
        description={
          gettext("Your next journey is just a click away. Start planning your dream vacation today.")
        }
        cta_label={gettext("Plan your first trip")}
        cta_to={~p"/trips/new"}
      />
      <div :if={!@empty_state?} class="mb-8">
        <.button :if={@current_user} link_type="live_redirect" to="trips/new" color="primary">
          <.icon name="hero-plus-solid" class="w-5 h-5 mr-2" />
          {gettext("Create trip")}
        </.button>
      </div>
      <.trips_grid :if={!@empty_state?} trips={@streams.plans} display_currency={@display_currency} />
    </.container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    display_currency = socket.assigns.current_user.default_currency || "EUR"
    plans = Planning.list_plans(socket.assigns.current_user)

    socket =
      socket
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Plans"))
      |> assign(display_currency: display_currency)
      |> assign(empty_state?: Enum.empty?(plans))
      |> stream(:plans, plans)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
