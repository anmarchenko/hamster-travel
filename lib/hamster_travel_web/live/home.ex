defmodule HamsterTravelWeb.Home do
  @moduledoc """
  Home page of Hamster Travel (showing landing for unauthenticated users and
  personalized home page for authenticated)
  """
  use HamsterTravelWeb, :live_view

  use Gettext, backend: HamsterTravelWeb.Gettext
  import HamsterTravelWeb.Planning.Grid

  alias HamsterTravel.Planning

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: home_nav_item())
      |> assign(page_title: gettext("Homepage"))

    current_user = socket.assigns.current_user

    socket =
      if current_user do
        socket
        |> stream(:next_plans, Planning.next_plans(current_user))
        |> stream(:last_trips, Planning.last_trips(current_user))
      else
        socket
      end

    {:ok, socket}
  end

  def subheader(assigns) do
    ~H"""
    <h2 class="my-8 text-xl font-semibold text-black dark:text-white">
      {render_slot(@inner_block)}
    </h2>
    """
  end
end
