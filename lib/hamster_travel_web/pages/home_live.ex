defmodule HamsterTravelWeb.HomeLive do
  @moduledoc """
  Home page of Hamster Travel (showing landing for unauthenticated users and
  personalized home page for authenticated)
  """
  use HamsterTravelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
