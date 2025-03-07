defmodule HamsterTravelWeb.Packing.IndexBackpacks do
  @moduledoc """
  Page showing all the backpacks
  """
  use HamsterTravelWeb, :live_view
  use Gettext, backend: HamsterTravelWeb.Gettext

  import HamsterTravelWeb.Packing.PackingComponents

  alias HamsterTravel.Packing

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
