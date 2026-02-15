defmodule HamsterTravelWeb.Planning.IndexPlans do
  @moduledoc """
  Page showing all the plans
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Planning.PlanningComponents

  alias HamsterTravel.Planning

  @page_size 12

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
      <.pagination
        :if={!@empty_state? && @total_pages > 1}
        class="mt-8"
        current_page={@current_page}
        total_pages={@total_pages}
        path="/plans?page=:page"
        link_type="live_patch"
      />
    </.container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    display_currency = socket.assigns.current_user.default_currency || "EUR"

    socket =
      socket
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Plans"))
      |> assign(display_currency: display_currency)
      |> assign(empty_state?: true)
      |> assign(current_page: 1)
      |> assign(total_pages: 1)
      |> stream(:plans, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = parse_page(params["page"])
    paginated_plans = Planning.list_plans_paginated(socket.assigns.current_user, page, @page_size)

    socket =
      socket
      |> assign(empty_state?: paginated_plans.total_entries == 0)
      |> assign(current_page: paginated_plans.page)
      |> assign(total_pages: paginated_plans.total_pages)
      |> stream(:plans, paginated_plans.entries, reset: true)

    {:noreply, socket}
  end

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end
end
