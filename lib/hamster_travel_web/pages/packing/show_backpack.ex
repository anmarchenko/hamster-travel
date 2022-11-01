defmodule HamsterTravelWeb.Packing.ShowBackpack do
  @moduledoc """
  Backpack page
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Container
  import HamsterTravelWeb.Header
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Link

  alias HamsterTravel.Packing
  alias HamsterTravelWeb.Packing.BackpackList

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    case Packing.get_backpack_by_slug(slug, socket.assigns.current_user) do
      nil ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}

      backpack ->
        socket =
          socket
          |> assign(active_nav: :backpacks)
          |> assign(page_title: backpack.name)
          |> assign(backpack: backpack)

        {:ok, socket}
    end
  end
end
