defmodule HamsterTravelWeb.Planning.CreateTrip do
  @moduledoc """
  Create trip form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravelWeb.Planning.Trips.FormComponent

  @impl true
  def mount(params, _session, socket) do
    is_draft = Map.get(params, "draft", false)

    socket =
      socket
      |> assign(active_nav: plans_nav_item())
      |> assign(page_title: gettext("Create a new trip"))
      |> assign(back_url: plans_url())
      |> assign(is_draft: is_draft)

    {:ok, socket}
  end
end
