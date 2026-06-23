defmodule HamsterTravelWeb.Planning.BudgetCategoryNew do
  @moduledoc """
  Adds a budget category from the Budget tab.
  """

  use HamsterTravelWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :edit, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  attr :trip, HamsterTravel.Planning.Trip, required: true
  attr :can_edit, :boolean, default: false

  @impl true
  def render(%{edit: true} = assigns) do
    ~H"""
    <div id={@id}>
      <.live_component
        module={HamsterTravelWeb.Planning.BudgetCategoryForm}
        id={"budget-category-form-new-#{@id}"}
        action={:new}
        trip={@trip}
        can_edit={@can_edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <button
        :if={@can_edit}
        type="button"
        phx-click="add"
        phx-target={@myself}
        class="inline-flex items-center gap-1.5 py-0.5 text-sm font-normal text-zinc-400 transition-colors hover:text-primary-600 focus-visible:text-primary-600 focus-visible:outline-none dark:text-zinc-500 dark:hover:text-primary-300"
      >
        <.icon name="hero-plus-solid" class="h-4 w-4" />
        {gettext("Add category")}
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("add", _params, socket) do
    if socket.assigns.can_edit do
      {:noreply, assign(socket, :edit, true)}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end
end
