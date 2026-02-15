defmodule HamsterTravelWeb.Planning.ActivityNew do
  @moduledoc """
  Button to add a new activity.
  """
  use HamsterTravelWeb, :live_component

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :day_index, :integer, required: true
  attr :edit, :boolean, default: false
  attr :class, :string, default: nil
  attr :can_edit, :boolean, default: false

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.live_component
        module={HamsterTravelWeb.Planning.ActivityForm}
        id={"activity-form-new-#{@id}"}
        trip={@trip}
        day_index={@day_index}
        action={:new}
        can_edit={@can_edit}
        on_finish={fn -> send(self(), {:finish_adding, "activity"}) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <a
        :if={@can_edit}
        href="#"
        phx-click="add_activity"
        phx-target={@myself}
        class="text-sm text-primary-500 hover:text-primary-800 dark:text-primary-500 dark:hover:text-primary-300"
      >
        <.inline>
          <.icon name="hero-plus-solid" class="w-5 h-5" />
          {gettext("Add activity")}
        </.inline>
      </a>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("add_activity", _, socket) do
    if socket.assigns.can_edit do
      send(self(), {:start_adding, "activity", socket.assigns.id})
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
