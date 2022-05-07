defmodule HamsterTravelWeb.Packing.IndexBackpacks do
  @moduledoc """
  Page showing all the backpacks
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravelWeb.Packing.BackpacksList

  import HamsterTravelWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :backpacks)
      |> assign(page_title: gettext("Backpacks"))
      |> assign(backpacks: HamsterTravel.backpacks())

    {:ok, socket}
  end
end
