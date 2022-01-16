defmodule HamsterTravelWeb.Packing.BackpacksLive do
  @moduledoc """
  Page showing all the backpacks
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :backpacks)
      |> assign(page_title: gettext("Backpacks"))

    {:ok, socket}
  end
end
