defmodule HamsterTravelWeb.Planning.Activity do
  @moduledoc """
  Live component responsible for showing and editing activities
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{Activity, Trip}

  attr(:activity, Activity, required: true)
  attr(:trip, Trip, required: true)
  attr(:display_currency, :string, required: true)
  attr(:index, :integer, required: true)

  def render(%{edit: true} = assigns) do
    ~H"""
    <div>
      <.live_component
        module={HamsterTravelWeb.Planning.ActivityForm}
        id={"activity-form-#{@activity.id}"}
        activity={@activity}
        trip={@trip}
        day_index={@activity.day_index}
        action={:edit}
        on_finish={fn -> send_update(@myself, edit: false) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      class="draggable-activity flex flex-col gap-y-1 py-1 sm:ml-[-1.5rem] sm:pl-[1.5rem] sm:hover:bg-zinc-100 sm:dark:hover:bg-zinc-700 cursor-grab active:cursor-grabbing"
      data-activity-id={@activity.id}
    >
      <.inline class={"2xl:text-lg #{activity_font(@activity.priority)}"}>
        <span
          class="cursor-pointer"
          phx-click={
            JS.toggle(
              to: "#activity-content-#{@activity.id}",
              in: {"transition-opacity duration-300", "opacity-0", "opacity-100"},
              out: {"transition-opacity duration-300", "opacity-100", "opacity-0"}
            )
          }
        >
          {"#{@index + 1}."}
          {@activity.name}
        </span>
        <.money_display
          money={@activity.expense.price}
          display_currency={@display_currency}
          class="font-normal"
        />
        <.activity_button phx-click="edit" phx-target={@myself}>
          <.icon name="hero-pencil" class="h-4 w-4" />
        </.activity_button>
        <.activity_button
          phx-click="delete"
          phx-target={@myself}
          data-confirm={gettext("Are you sure you want to delete this activity?")}
        >
          <.icon name="hero-trash" class="h-4 w-4" />
        </.activity_button>
      </.inline>
      <div id={"activity-content-#{@activity.id}"} class="hidden flex flex-col gap-y-1">
        <.external_link :if={@activity.link} link={@activity.link} />
        <.activity_feature label={gettext("Address")} value={@activity.address} />
        <.formatted_text :if={@activity.description} text={@activity.description} class="mt-3" />
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
    case Planning.delete_activity(socket.assigns.activity) do
      {:ok, _activity} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to delete activity"))}
    end
  end

  # Priority 3 -> Bold, 2 -> Normal, 1 -> Italic/Secondary
  defp activity_font(3), do: "font-bold"
  defp activity_font(2), do: "font-normal"
  defp activity_font(1), do: "italic font-light text-zinc-400"
  defp activity_font(_), do: "font-normal"

  defp activity_feature(%{value: nil} = assigns) do
    ~H"""
    """
  end

  defp activity_feature(assigns) do
    ~H"""
    <.secondary class="max-w-prose">
      {@label}: {@value}
    </.secondary>
    """
  end

  attr :rest, :global
  slot :inner_block, required: true

  defp activity_button(assigns) do
    ~H"""
    <span
      class="cursor-pointer hover:text-zinc-900 hover:dark:text-zinc-100"
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
