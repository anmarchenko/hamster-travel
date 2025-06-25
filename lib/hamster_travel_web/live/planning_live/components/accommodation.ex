defmodule HamsterTravelWeb.Planning.Accommodation do
  @moduledoc """
  Live component responsible for showing and editing accommodations
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Accommodation
  alias HamsterTravelWeb.Cldr, as: Formatters

  import HamsterTravelWeb.Icons.HomeSimple

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :accommodation, HamsterTravel.Planning.Accommodation, required: true

  def render(%{edit: true} = assigns) do
    ~H"""
    <span>edit mode to be implemented</span>
    """
  end

  def render(%{edit: false} = assigns) do
    assigns = assign(assigns, :price, Accommodation.price_per_night(assigns.accommodation))

    ~H"""
    <div class="flex flex-col gap-y-1">
      <.inline class="gap-[0px]">
        <h2 class="text-md font-bold text-slate-800 leading-tight pr-3">
          {@accommodation.name}
        </h2>
        <p class="text-md font-bold text-purple-600 whitespace-nowrap ml-auto flex-shrink-0">
          {Formatters.format_money(@price.amount, @price.currency)} / {gettext("night")}
        </p>
      </.inline>
      <div class="flex-grow space-y-3 text-sm text-slate-600 mb-2 mt-2">
        <div :if={@accommodation.address} class="flex justify-between items-center">
          <div class="flex items-center flex-grow mr-2">
            <span class="mr-1 flex-shrink-0">
              <.icon name="hero-map-pin" class="w-5 h-5" />
            </span>
            <span class="leading-snug">
              {@accommodation.address}
            </span>
          </div>
          <div class="flex items-center space-x-1 flex-shrink-0">
            <.icon_button
              size="xs"
              phx-click="edit"
              phx-target={@myself}
              class="justify-self-end ml-2"
            >
              <.icon name="hero-pencil" class="w-4 h-4" />
            </.icon_button>
            <.icon_button
              class="justify-self-end"
              size="xs"
              phx-click="delete"
              phx-target={@myself}
              data-confirm={
                gettext("Are you sure you want to delete %{accommodation_name} from your trip?",
                  accommodation_name: @accommodation.name
                )
              }
            >
              <.icon name="hero-trash" class="w-4 h-4" />
            </.icon_button>
          </div>
        </div>
      </div>

      <.external_link link={@accommodation.link} class="mb-3" />

      <div :if={@accommodation.note} class="pt-4 border-t border-slate-200">
        <div class="flex items-center text-sm text-slate-700 bg-gray-50/70 p-3.5 rounded-lg">
          <.icon name="hero-information-circle" class="w-4 h-4 mr-2" />
          <p class="leading-relaxed">{@accommodation.note}</p>
        </div>
      </div>
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
