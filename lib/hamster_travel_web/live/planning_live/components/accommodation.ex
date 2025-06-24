defmodule HamsterTravelWeb.Planning.Accommodation do
  @moduledoc """
  Live component responsible for showing and editing accommodations
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravelWeb.Cldr, as: Formatters

  import HamsterTravelWeb.Icons.{Budget, HomeSimple}

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :accommodation, HamsterTravel.Planning.Accommodation, required: true

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div class="flex flex-col gap-y-1">
      <.inline class="font-bold">
        {@accommodation.name}
      </.inline>
      <.inline>
        <.budget />
        {Formatters.format_money(
          @accommodation.expense.price.amount,
          @accommodation.expense.price.currency
        )}
      </.inline>
      <.external_link link={@accommodation.link} />
      <.inline>
        <.home_simple />
        {@accommodation.address}
      </.inline>
      <.secondary>
        {@accommodation.note}
      </.secondary>
    </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    socket =
      socket
      |> assign(:edit, true)

    {:noreply, socket}
  end

  def handle_event("delete", _, socket) do
    case Planning.delete_accommodation(socket.assigns.accommodation) do
      {:ok, _accommodation} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete accommodation"))}
    end
  end
end
