defmodule HamsterTravelWeb.Packing.BackpacksLive do
  @moduledoc """
  Page showing all the backpacks
  """
  use HamsterTravelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :backpacks)
      |> assign(page_title: "Рюкзачки")

    {:ok, socket}
  end
end
