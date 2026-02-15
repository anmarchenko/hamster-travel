defmodule HamsterTravelWeb.Packing.IndexBackpacks do
  @moduledoc """
  Page showing all the backpacks
  """
  use HamsterTravelWeb, :live_view
  use Gettext, backend: HamsterTravelWeb.Gettext

  import HamsterTravelWeb.Packing.PackingComponents

  alias HamsterTravel.Packing

  @page_size 12

  @impl true
  def render(assigns) do
    ~H"""
    <.container>
      <div class="mb-8">
        <.button link_type="live_redirect" to="backpacks/new" color="primary">
          <.icon name="hero-plus-solid" class="w-5 h-5 mr-2" />
          {gettext("Create backpack")}
        </.button>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
        <.backpack_card :for={backpack <- @backpacks} backpack={backpack} />
      </div>
      <.pagination
        :if={!@empty_state? && @total_pages > 1}
        class="mt-8"
        current_page={@current_page}
        total_pages={@total_pages}
        path="/backpacks?page=:page"
        link_type="live_patch"
      />
    </.container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: backpacks_nav_item())
      |> assign(page_title: gettext("Backpacks"))
      |> assign(backpacks: [])
      |> assign(empty_state?: true)
      |> assign(current_page: 1)
      |> assign(total_pages: 1)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = parse_page(params["page"])

    paginated_backpacks =
      Packing.list_backpacks_paginated(socket.assigns.current_user, page, @page_size)

    socket =
      socket
      |> assign(backpacks: paginated_backpacks.entries)
      |> assign(empty_state?: paginated_backpacks.total_entries == 0)
      |> assign(current_page: paginated_backpacks.page)
      |> assign(total_pages: paginated_backpacks.total_pages)

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
