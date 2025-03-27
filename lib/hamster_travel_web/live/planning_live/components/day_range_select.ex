defmodule HamsterTravelWeb.Planning.DayRangeSelect do
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Planning.PlanningComponents, only: [day_label: 1]

  # preview: https://v0.dev/chat/date-range-select-js-fP6afJvlffR

  attr :start_day_field, Phoenix.HTML.FormField, required: true
  attr :end_day_field, Phoenix.HTML.FormField, required: true

  attr :label, :string, required: true
  attr :duration, :integer, required: true
  attr :start_date, Date, required: false

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.label for={@start_day_field.id}>{@label}</.label>
      
    <!-- Day Range Select Component -->
      <div
        id={"day-range-select-#{@id}"}
        class="day-range-select relative"
        phx-hook="DayRangeSelect"
        class="space-y-4"
      >
        <button
          id="day-range-trigger"
          class="w-full flex items-center justify-between px-3 py-2 text-left bg-white border border-gray-300 rounded-md shadow-sm text-sm"
        >
          <span id="selected-range-display">
            <%= cond do %>
              <% @start_day_selection == nil -> %>
                {gettext("Select day")}
              <% @start_day_selection == @end_day_selection -> %>
                <.day_label day_index={@start_day_selection} start_date={@start_date} />
              <% true -> %>
                <.day_label day_index={@start_day_selection} start_date={@start_date} /> -
                <.day_label day_index={@end_day_selection} start_date={@start_date} />
            <% end %>
          </span>
          <.icon name="hero-chevron-down" class="h-5 w-5 text-gray-400" />
        </button>
        
    <!-- Dropdown -->
        <div
          id="day-range-dropdown"
          class="day-range-select-dropdown absolute z-50 w-max max-w-[330px] sm:max-w-md mt-1 border border-gray-200 rounded-md shadow-lg overflow-visible bg-white dark:bg-zinc-900 hidden"
        >
          <!-- Selection Step Indicator -->
          <div class="px-3 py-2 border-b border-gray-300">
            <span
              id="selection-step-badge"
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100"
            >
              <span id="selection-step-badge-text-start">{gettext("Select start day")}</span>
              <span id="selection-step-badge-text-end" class="hidden">
                {gettext("Select end day")}
              </span>
            </span>
          </div>
          
    <!-- Days List -->
          <div class="max-h-60 overflow-y-auto p-1">
            <div id="days-container" class="space-y-1">
              <%= for day <- @days do %>
                <%!-- note that we need to mark the ones that are in the range and the ones that are disabled --%>
                <div
                  phx-click="select_day"
                  phx-value-day={day}
                  class="day-item flex items-center gap-2 px-3 py-2 rounded-md cursor-pointer hover:bg-gray-100"
                >
                  <input
                    type="checkbox"
                    class="pc-checkbox"
                    checked={day >= @start_day_selection && day <= @end_day_selection}
                    readonly
                  />
                  <span>
                    <.day_label day_index={day} start_date={@start_date} />
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <.hidden_input
        form={@start_day_field.form}
        field={@start_day_field.field}
        value={@start_day_selection}
      />
      <.hidden_input
        form={@end_day_field.form}
        field={@end_day_field.field}
        value={@end_day_selection}
      />
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(selection_step: "start")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    start_date = assigns[:start_date] || nil

    socket =
      socket
      |> assign(
        start_date: start_date,
        # the results of this field
        start_day_selection: assigns.start_day_field.value,
        end_day_selection: assigns.end_day_field.value,
        # the days list, comes from the server when the component is mounted
        days: Enum.map(1..assigns.duration, fn index -> index end)
      )
      |> assign(assigns)

    {:ok, socket}
  end
end
