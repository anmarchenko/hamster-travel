defmodule HamsterTravelWeb.Planning.ActivityNew do
  @moduledoc """
  Button to add a new activity.
  """
  use HamsterTravelWeb, :live_component

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, required: true
  attr :edit, :boolean, default: false
  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <div :if={!@edit} class="mt-2">
        <.icon_button
          size="sm"
          phx-click="add_activity"
          phx-target={@myself}
          tooltip={gettext("Add activity")}
        >
          <.icon name="hero-plus" class="w-4 h-4" />
        </.icon_button>
      </div>

      <div :if={@edit} class="mt-2">
        <.live_component
          module={HamsterTravelWeb.Planning.ActivityForm}
          id={"activity-form-new-#{@id}"}
          trip={@trip}
          day_index={@day_index}
          action={:new}
          on_finish={fn -> send(self(), {:finish_adding, "activity"}) end}
        />
      </div>
    </div>
    """
  end

  def handle_event("add_activity", _, socket) do
    send(self(), {:start_adding, "activity", socket.assigns.id})
    {:noreply, socket}
  end
end
