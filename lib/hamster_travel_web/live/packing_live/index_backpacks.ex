defmodule HamsterTravelWeb.Packing.IndexBackpacks do
  @moduledoc """
  Page showing all the backpacks
  """
  use HamsterTravelWeb, :live_view
  use Gettext, backend: HamsterTravelWeb.Gettext

  import HamsterTravelWeb.Packing.PackingComponents

  alias HamsterTravel.Packing

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
    </.container>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: backpacks_nav_item())
      |> assign(page_title: gettext("Backpacks"))
      |> assign(backpacks: Packing.list_backpacks(socket.assigns.current_user))

    {:ok, socket}
  end
end
