defmodule HamsterTravelWeb.Planning.Accommodation do
  @moduledoc """
  Live component responsible for showing and editing accommodations
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Accommodation
  alias HamsterTravelWeb.Cldr, as: Formatters

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :accommodation, HamsterTravel.Planning.Accommodation, required: true

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.AccommodationForm}
        id={"accommodation-form-#{@accommodation.id}"}
        accommodation={@accommodation}
        trip={@trip}
        day_index={@accommodation.start_day}
        action={:edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    assigns = assign(assigns, :price, Accommodation.price_per_night(assigns.accommodation))

    ~H"""
    <div class="flex flex-col gap-y-1">
      <.inline class="gap-[0px]">
        <h2 class="text-md font-bold text-slate-800 dark:text-slate-200 leading-tight pr-3">
          {@accommodation.name}
        </h2>
        <p class="text-md font-bold text-purple-600 dark:text-purple-400 whitespace-nowrap ml-auto flex-shrink-0">
          {Formatters.format_money(@price.amount, @price.currency)} / {gettext("night")}
        </p>
      </.inline>

      <div class="flex-grow space-y-3 text-sm text-slate-600 dark:text-slate-400 mb-2 mt-2">
        <div :if={@accommodation.link} class="flex justify-between items-center">
          <.external_link link={@accommodation.link} />

          <.action_buttons accommodation={@accommodation} myself={@myself} />
        </div>

        <div
          :if={@accommodation.address || !@accommodation.link}
          class="flex justify-between items-center"
        >
          <div :if={@accommodation.address} class="flex items-center flex-grow mr-2">
            <span class="leading-snug">
              {@accommodation.address}
            </span>
          </div>
          <div :if={!@accommodation.link}>
            <.action_buttons accommodation={@accommodation} myself={@myself} />
          </div>
        </div>
      </div>

      <div :if={@accommodation.note} class="pt-4 border-t border-slate-200 dark:border-slate-700">
        <div class="flex items-center text-sm text-slate-700 dark:text-slate-300 bg-gray-50/70 dark:bg-slate-800/70 p-3.5 rounded-lg">
          <.icon name="hero-information-circle" class="w-4 h-4 mr-2" />
          <p class="leading-relaxed">{@accommodation.note}</p>
        </div>
      </div>
    </div>
    """
  end

  defp action_buttons(assigns) do
    ~H"""
    <div class="flex items-center space-x-1 flex-shrink-0">
      <.icon_button size="xs" phx-click="edit" phx-target={@myself} class="justify-self-end">
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
