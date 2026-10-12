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
  attr(:can_edit, :boolean, default: false)
  attr(:edit, :boolean, default: false)

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
        can_edit={@can_edit}
        position={@index + 1}
        on_finish={fn -> send(self(), :close_form) end}
      />
    </div>
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      class={[
        "flex w-full max-w-3xl flex-col gap-y-1.5 rounded-md border-l-4 px-2.5 py-1.5 transition-colors duration-200 min-[1920px]:max-w-6xl",
        activity_priority_accent(@activity.priority),
        @can_edit &&
          "draggable-activity sm:hover:bg-zinc-50 sm:dark:hover:bg-zinc-800"
      ]}
      data-activity-id={@activity.id}
    >
      <div class="flex flex-col gap-1.5 sm:flex-row sm:items-start sm:justify-between sm:gap-4">
        <div class="flex min-w-0 flex-1 items-center gap-2">
          <span
            class={[
              "inline-flex h-5 min-w-5 shrink-0 items-center justify-center rounded-md px-1.5 text-xs font-semibold leading-none",
              @can_edit && "cursor-grab active:cursor-grabbing",
              activity_priority_badge(@activity.priority)
            ]}
            data-activity-drag-handle
          >
            {@index + 1}
          </span>
          <span class="min-w-0 flex-1 leading-snug">
            <span class="select-text text-sm font-semibold leading-snug text-zinc-900 dark:text-zinc-200 2xl:text-base">
              {@activity.name}
            </span>
            <button
              type="button"
              aria-expanded="false"
              aria-label={gettext("Toggle activity details")}
              title={gettext("Toggle activity details")}
              class="ml-1 inline-flex h-6 w-6 items-center justify-center align-middle rounded text-zinc-400 transition-colors hover:bg-zinc-100 hover:text-zinc-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 dark:text-zinc-500 dark:hover:bg-zinc-800 dark:hover:text-zinc-200"
              data-activity-toggle
              phx-click={toggle_activity_details(@activity.id)}
            >
              <.icon
                id={"activity-chevron-right-#{@activity.id}"}
                name="hero-chevron-right"
                class="h-4 w-4"
              />
              <.icon
                id={"activity-chevron-down-#{@activity.id}"}
                name="hero-chevron-down"
                class="hidden h-4 w-4"
              />
            </button>
          </span>
        </div>
        <div class="flex items-center gap-2 pl-7 sm:w-44 sm:justify-end sm:pl-0 sm:pt-0.5">
          <.money_display
            money={@activity.expense.price}
            display_currency={@display_currency}
            class="text-base font-normal tabular-nums text-zinc-500 dark:text-zinc-400 sm:text-right 2xl:text-lg"
          />
          <div :if={@can_edit} class="flex shrink-0 items-center gap-1">
            <.icon_button
              size="xs"
              id={"move-activity-#{@activity.id}"}
              type="button"
              aria-label={gettext("Move to day")}
              title={gettext("Move to day")}
              aria-haspopup="dialog"
              aria-controls={"move-activity-modal-#{@activity.id}"}
              phx-click={show_modal("move-activity-modal-#{@activity.id}")}
              class="!h-5 !w-5 !p-0 min-h-0 bg-transparent hover:bg-transparent text-slate-500 dark:text-slate-400 hover:text-zinc-900 dark:hover:text-zinc-100"
            >
              <.icon name="hero-calendar-days" class="h-4 w-4" />
            </.icon_button>
            <.edit_delete_buttons
              class="shrink-0"
              edit_target={@myself}
              delete_target={@myself}
              delete_confirm={
                gettext("Are you sure you want to delete activity \"%{name}\"?", name: @activity.name)
              }
            />
          </div>
        </div>
      </div>
      <div id={"activity-content-#{@activity.id}"} class="hidden flex flex-col gap-y-1 pl-7">
        <.secondary
          :if={@activity.link}
          tag="div"
          italic={false}
          class="flex items-start gap-2 max-w-prose"
        >
          <.icon name="hero-link" class="h-4 w-4 mt-1 text-zinc-400" />
          <.external_link link={@activity.link} />
        </.secondary>
        <.activity_feature icon="hero-map-pin" value={@activity.address} />
        <.formatted_text :if={@activity.description} text={@activity.description} class="mt-3" />
      </div>
      <.modal
        :if={@can_edit}
        id={"move-activity-modal-#{@activity.id}"}
        max_width_class="max-w-lg"
      >
        <h2 id={"move-activity-modal-#{@activity.id}-title"} class="text-lg font-semibold">
          {gettext("Move to day")}
        </h2>
        <p
          id={"move-activity-modal-#{@activity.id}-description"}
          class="mt-2 text-sm text-zinc-500 dark:text-zinc-400"
        >
          {@activity.name}
        </p>
        <div
          class="-mr-8 mt-4 max-h-60 overflow-y-auto overscroll-contain pr-6 [scrollbar-gutter:stable] [scrollbar-width:thin] lg:max-h-[min(65vh,40rem)]"
          data-activity-day-picker
        >
          <button
            :for={day_index <- 0..(@trip.duration - 1)}
            type="button"
            phx-click={
              hide_modal("move-activity-modal-#{@activity.id}")
              |> JS.push("move_activity",
                value: %{
                  activity_id: to_string(@activity.id),
                  new_day_index: day_index,
                  position: length(Planning.activities_for_day(day_index, @trip.activities))
                }
              )
            }
            data-day-index={day_index}
            disabled={day_index == @activity.day_index}
            class="flex w-full items-center justify-between gap-2 rounded px-3 py-2 text-left text-sm hover:bg-zinc-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary-500 disabled:cursor-default disabled:opacity-50 dark:hover:bg-zinc-800"
          >
            <span class="shrink-0">{gettext("Day")} {day_index + 1}</span>
            <span class="ml-auto flex items-center gap-3">
              <span :if={@trip.start_date} class="text-right text-zinc-500 dark:text-zinc-400">
                {Formatter.date_with_weekday(Date.add(@trip.start_date, day_index))}
              </span>
              <span class="h-4 w-4 shrink-0" aria-hidden="true">
                <.icon :if={day_index == @activity.day_index} name="hero-check" class="h-4 w-4" />
              </span>
            </span>
          </button>
        </div>
      </.modal>
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
      send(self(), {:open_form, "edit", "activity", socket.assigns.activity.id})
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  def handle_event("delete", _, socket) do
    if socket.assigns.can_edit do
      case Planning.delete_activity(socket.assigns.activity) do
        {:ok, _activity} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, gettext("Failed to delete activity"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Only trip participants can edit this trip."))}
    end
  end

  defp activity_priority_accent(3), do: "border-zinc-900 dark:border-zinc-100"
  defp activity_priority_accent(2), do: "border-zinc-400 dark:border-zinc-600"
  defp activity_priority_accent(1), do: "border-zinc-200 dark:border-zinc-800"
  defp activity_priority_accent(_), do: "border-zinc-200 dark:border-zinc-800"

  defp activity_priority_badge(3),
    do: "bg-zinc-200 text-zinc-950 dark:bg-zinc-700 dark:text-zinc-50"

  defp activity_priority_badge(2),
    do: "bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300"

  defp activity_priority_badge(1),
    do: "bg-zinc-50 text-zinc-400 dark:bg-zinc-900 dark:text-zinc-500"

  defp activity_priority_badge(_),
    do: "bg-zinc-50 text-zinc-400 dark:bg-zinc-900 dark:text-zinc-500"

  defp toggle_activity_details(activity_id) do
    JS.toggle(
      to: "#activity-content-#{activity_id}",
      in: {"transition-opacity duration-300", "opacity-0", "opacity-100"},
      out: {"transition-opacity duration-300", "opacity-100", "opacity-0"}
    )
    |> JS.toggle_class("hidden", to: "#activity-chevron-right-#{activity_id}")
    |> JS.toggle_class("hidden", to: "#activity-chevron-down-#{activity_id}")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"})
  end

  attr(:icon, :string, required: true)
  attr(:value, :string, required: true)

  defp activity_feature(%{value: nil} = assigns) do
    ~H"""
    """
  end

  defp activity_feature(assigns) do
    ~H"""
    <.secondary tag="div" italic={false} class="flex items-start gap-2 max-w-prose">
      <.icon name={@icon} class="h-4 w-4 mt-1 text-zinc-400" />
      <span>{@value}</span>
    </.secondary>
    """
  end
end
