defmodule HamsterTravelWeb.Home do
  @moduledoc """
  Home page of Hamster Travel (showing landing for unauthenticated users and
  personalized home page for authenticated)
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Gettext
  import HamsterTravelWeb.Header
  import HamsterTravelWeb.Link
  import HamsterTravelWeb.Planning.Grid

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :home)
      |> assign(page_title: gettext("Homepage"))
      |> assign(next_plans: HamsterTravel.next_plans())
      |> assign(last_plans: HamsterTravel.last_plans())

    {:ok, socket}
  end

  def subheader(assigns) do
    ~H"""
    <h2 class="my-8 text-xl font-semibold text-black dark:text-white">
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end
end
