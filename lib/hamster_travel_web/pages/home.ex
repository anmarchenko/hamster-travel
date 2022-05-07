defmodule HamsterTravelWeb.Home do
  @moduledoc """
  Home page of Hamster Travel (showing landing for unauthenticated users and
  personalized home page for authenticated)
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :home)
      |> assign(page_title: gettext("Homepage"))

    {:ok, socket}
  end
end
