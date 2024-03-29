defmodule HamsterTravelWeb.Accounts.Profile do
  @moduledoc """
  User profile
  """
  use HamsterTravelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: gettext("My profile"))

    {:ok, socket}
  end
end
