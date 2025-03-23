defmodule HamsterTravelWeb.Planning.DayRangeSelect do
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Planning.PlanningComponents, only: [day_label: 1]

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
                <.day_label day_index={@end_day_selection} start_date={@end_date} />
            <% end %>
          </span>
          <.icon name="hero-chevron-down" class="h-5 w-5 text-gray-400" />
        </button>
        <!-- Dropdown -->
        <div
          id="day-range-dropdown"
          class="day-range-select-dropdown absolute z-50 w-max max-w-[330px] sm:max-w-md mt-1 border border-gray-200 rounded-md shadow-lg overflow-visible bg-white dark:bg-zinc-900 hidden"
        >
          I AM A DROPDOWN I AM A DROPDOWN I AM A DROPDOWN
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
      |> assign(
        # remove this - belongs to client side
        open: false,
        filter_term: "",
        selection_step: "start"
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    start_date = assigns[:start_date]
    end_date = if start_date != nil, do: Date.add(start_date, assigns[:duration] - 1), else: nil

    socket =
      socket
      |> assign(
        end_date: end_date,
        # the results of this field
        start_day_selection: assigns.start_day_field.value,
        end_day_selection: assigns.end_day_field.value,
        # the days list, comes from the server when the component is mounted
        days:
          Enum.map(1..assigns.duration, fn index ->
            date =
              if start_date != nil do
                Date.add(start_date, index - 1)
              else
                nil
              end

            %{number: index, date: date, visible: true}
          end)
      )
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_dropdown", _, socket) do
    socket = assign(socket, open: !socket.assigns.open, filter_term: "")

    {:noreply, socket}
  end
end
