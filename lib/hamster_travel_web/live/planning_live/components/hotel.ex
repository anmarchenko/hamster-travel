defmodule HamsterTravelWeb.Planning.Hotel do
  @moduledoc """
  Live component responsible for showing and editing hotels
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Icons.{Budget, HomeSimple}

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1">
      <.inline>
        <.home_simple />
        <%= @hotel.name %>
      </.inline>
      <.inline>
        <.budget />
        <%= Formatter.format_money(@hotel.price, @hotel.price_currency) %>
      </.inline>
      <.secondary>
        <%= @hotel.comment %>
      </.secondary>
      <.external_links links={@hotel.links} />
    </div>
    """
  end
end
