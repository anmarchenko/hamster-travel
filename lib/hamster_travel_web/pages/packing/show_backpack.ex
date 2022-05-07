defmodule HamsterTravelWeb.Packing.ShowBackpack do
  @moduledoc """
  Backpack page
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Link
  import HamsterTravelWeb.Packing.BackpackComponents

  alias HamsterTravelWeb.Packing.List

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    case HamsterTravel.find_backpack_by_slug(slug) do
      {:ok, backpack} ->
        socket =
          socket
          |> assign(active_nav: :backpacks)
          |> assign(page_title: backpack.name)
          |> assign(backpack: backpack)

        {:ok, socket}

      {:error, :not_found} ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}
    end
  end
end
