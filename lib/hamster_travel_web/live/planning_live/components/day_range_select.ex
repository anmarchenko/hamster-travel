defmodule HamsterTravelWeb.Planning.DayRangeSelect do
  use HamsterTravelWeb, :live_component

  attr :id, :string, required: true
  attr :start_day_field, Phoenix.HTML.FormField, required: true
  attr :end_day_field, Phoenix.HTML.FormField, required: true

  attr :label, :string, required: true
  attr :duration, :integer, required: true
  attr :start_date, Date, required: false

  @impl true
  def render(assigns) do
    ~H"""
    <div class="day-range-select-live-component">
      <.label for={@start_day_field.id}>{@label}</.label>

      <div id={"day-range-select-#{@id}"} class="day-range-select relative" class="space-y-4">
        <button
          id="day-range-trigger"
          phx-click={toggle_dropdown(@id)}
          class="w-full flex items-center justify-between px-3 py-2 text-left bg-white border border-gray-300 rounded-md shadow-sm text-sm"
        >
          <span id="selected-range-display">
            <%= cond do %>
              <% @start_day_selection == nil -> %>
                {gettext("Select day")}
              <% @start_day_selection == @end_day_selection -> %>
                <span :if={@start_date == nil}>{gettext("Day")}</span>
                <.short_day_label day_index={@start_day_selection} start_date={@start_date} />
              <% true -> %>
                <span :if={@start_date == nil}>{gettext("Days")}</span>
                <.short_day_label day_index={@start_day_selection} start_date={@start_date} /> -
                <.short_day_label day_index={@end_day_selection} start_date={@start_date} />
            <% end %>
          </span>
          <.icon name="hero-calendar-date-range" class="h-5 w-5 text-gray-400" />
        </button>
        
    <!-- Dropdown -->
        <div
          id={"day-range-dropdown-#{@id}"}
          class="day-range-select-dropdown absolute z-50 w-max max-w-[330px] sm:max-w-md mt-1 border border-gray-200 rounded-md shadow-lg overflow-visible bg-white dark:bg-zinc-900 hidden"
          phx-hook="DayRangeSelect"
          phx-update="ignore"
          data-selection-start-init={@start_day_selection}
          data-selection-end-init={@end_day_selection}
          data-selection-step="start"
          data-close-dropdown={close_dropdown(@id)}
        >
          <!-- Days List -->
          <div class="max-h-60 overflow-y-auto p-2">
            <div id="day-selector-grid" class="grid grid-cols-7 gap-1">
              <div
                :for={day <- @days}
                data-day={day}
                class="day-item flex justify-center items-center h-8 w-8 text-sm rounded-md cursor-pointer transition duration-150 ease-in-out border border-gray-300 hover:bg-gray-200"
              >
                <.short_day_label day_index={day} start_date={@start_date} />
              </div>
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
        days: Enum.map(0..(assigns.duration - 1), fn index -> index end)
      )
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "day_range_selected",
        %{"start_day" => start_day, "end_day" => end_day},
        socket
      ) do
    # Convert string numbers to integers
    start_day = String.to_integer("#{start_day}")
    end_day = String.to_integer("#{end_day}")

    socket =
      socket
      |> assign(
        start_day_selection: start_day,
        end_day_selection: end_day
      )

    {:noreply, push_event(socket, "closeDropdown", %{})}
  end

  def toggle_dropdown(id) do
    JS.toggle(
      to: "#day-range-dropdown-#{id}",
      in: {"transition ease-out duration-100", "opacity-0 scale-95", "opacity-100 scale-100"},
      out: {"transition ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
  end

  def close_dropdown(id) do
    JS.hide(
      to: "#day-range-dropdown-#{id}",
      transition:
        {"transition ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
  end

  def short_day_label(%{start_date: nil} = assigns) do
    ~H"""
    {@day_index + 1}
    """
  end

  def short_day_label(assigns) do
    ~H"""
    {Formatter.date_without_year(Date.add(@start_date, @day_index))}
    """
  end
end
