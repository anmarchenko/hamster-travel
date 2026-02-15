defmodule HamsterTravelWeb.Planning.Accommodation do
  @moduledoc """
  Live component responsible for showing and editing accommodations
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Accommodation

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :accommodation, HamsterTravel.Planning.Accommodation, required: true
  attr :display_currency, :string, required: true
  attr :can_edit, :boolean, default: false

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
        can_edit={@can_edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    assigns = assign(assigns, :price, Accommodation.price_per_night(assigns.accommodation))

    ~H"""
    <div class="flex flex-col gap-y-2 p-2">
      <div class="flex items-center justify-between gap-3">
        <div class="min-w-0 flex-1">
          <h2 class="text-md font-bold leading-tight wrap-break-word">
            {@accommodation.name}
          </h2>
        </div>
        <.edit_delete_buttons
          :if={@can_edit}
          edit_target={@myself}
          delete_target={@myself}
          delete_confirm={
            gettext("Are you sure you want to delete %{accommodation_name} from your trip?",
              accommodation_name: @accommodation.name
            )
          }
        />
      </div>

      <div class="text-left">
        <.money_display
          money={@price}
          display_currency={@display_currency}
          class="inline-flex text-md font-bold"
        >
          <:suffix>&nbsp;/&nbsp;{gettext("night")}</:suffix>
        </.money_display>
      </div>

      <div class="grow space-y-2 text-sm text-slate-600 dark:text-slate-400">
        <div :if={@accommodation.link}>
          <.external_link link={@accommodation.link} />
        </div>

        <div :if={@accommodation.address} class="flex items-start gap-2">
          <.icon name="hero-map-pin" class="w-4 h-4 mt-0.5 text-slate-400" />
          <span class="leading-snug">
            {@accommodation.address}
          </span>
        </div>
      </div>

      <.note :if={formatted_text_present?(@accommodation.note)}>
        <.formatted_text text={@accommodation.note} />
      </.note>
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
    if socket.assigns.can_edit do
      socket =
        socket
        |> assign(:edit, true)

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_accommodation(socket.assigns.accommodation) do
        {:ok, _accommodation} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, gettext("Failed to delete accommodation"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
