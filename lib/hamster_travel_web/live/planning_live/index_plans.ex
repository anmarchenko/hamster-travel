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
      <div :if={!@empty_state?} class="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center">
        <.button :if={@current_user} link_type="live_redirect" to="trips/new" color="primary">
          <.icon name="hero-plus-solid" class="w-5 h-5 mr-2" />
          {gettext("Create trip")}
        </.button>
        <form
          id="plans-search-form"
          phx-change="search"
          phx-submit="search"
          class="sm:ml-auto w-full sm:max-w-sm"
        >
          <label for="plans-search-input" class="sr-only">{gettext("Search trips")}</label>
          <input
            id="plans-search-input"
            type="search"
            name="q"
            value={@search_query || ""}
            phx-debounce="300"
            placeholder={gettext("Search by trip, city, country")}
            class="w-full rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm text-zinc-900 shadow-sm focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20 dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
          />
        </form>
      </div>
      <p
        :if={!@empty_state? && @total_entries == 0}
        class="mb-8 text-sm text-zinc-600 dark:text-zinc-400"
      >
        {gettext("No trips found for your search.")}
      </p>
      <.trips_grid
        :if={!@empty_state? && @total_entries > 0}
        trips={@streams.plans}
        display_currency={@display_currency}
      />
      <.pagination
        :if={!@empty_state? && @total_entries > 0 && @total_pages > 1}
        class="mt-8"
        current_page={@current_page}
        total_pages={@total_pages}
        path={@pagination_path}
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
      |> assign(total_entries: 0)
      |> assign(search_query: nil)
      |> assign(pagination_path: pagination_path(nil))
      |> stream(:plans, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    search_query = parse_search_query(params["q"])
    page = parse_page(params["page"])

    paginated_plans =
      Planning.list_plans_paginated(socket.assigns.current_user, page, @page_size, search_query)

    socket =
      socket
      |> assign(empty_state?: paginated_plans.total_entries == 0 and is_nil(search_query))
      |> assign(current_page: paginated_plans.page)
      |> assign(total_pages: paginated_plans.total_pages)
      |> assign(total_entries: paginated_plans.total_entries)
      |> assign(search_query: search_query)
      |> assign(pagination_path: pagination_path(search_query))
      |> stream(:plans, paginated_plans.entries, reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => search_query}, socket) do
    search_query = parse_search_query(search_query)

    {:noreply, push_patch(socket, to: search_path(search_query))}
  end

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end

  defp parse_search_query(nil), do: nil

  defp parse_search_query(search_query) when is_binary(search_query) do
    case String.trim(search_query) do
      "" -> nil
      term -> term
    end
  end

  defp search_path(search_query) do
    path_with_query("/plans", [{"q", search_query}])
  end

  defp pagination_path(search_query) do
    path_with_query("/plans", [{"page", ":page"}, {"q", search_query}])
  end

  defp path_with_query(base_path, params) do
    query =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> URI.encode_query()

    if query == "" do
      base_path
    else
      "#{base_path}?#{query}"
    end
  end
end
