defmodule HamsterTravelWeb.Planning.CityInput do
  use HamsterTravelWeb, :live_component

  import LiveSelect

  alias HamsterTravel.Geo

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.label for={@field.id}><%= @label %></.label>
      <.live_select
        field={@field}
        phx-target={@myself}
        text_input_class="pc-text-input"
        dropdown_class="absolute rounded-md shadow z-50 bg-white inset-x-0 top-full max-h-32 overflow-y-scroll w-max"
        active_option_class="font-bold bg-gray-200"
        update_min_len={2}
      >
        <:option :let={option}>
          <.inline>
            <.flag size={16} country={option.value.country} />
            <%= option.label %>
          </.inline>
        </:option>
      </.live_select>
    </div>
    """
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    cities =
      text
      |> Geo.search_cities()
      |> Enum.map(fn city ->
        [
          label: Geo.city_text(city),
          value: %{
            id: city.id,
            country: city.country.iso
          }
        ]
      end)

    send_update(LiveSelect.Component, id: live_select_id, options: cities)

    {:noreply, socket}
  end

  # TMP: https://fly.io/phoenix-files/phoenix-liveview-and-sqlite-autocomplete/

  # @impl true
  # def render(assigns) do
  #   ~H"""
  #   <div>
  #     <.typeahead_input value={@query} phx-target={@myself} phx-keyup="do-search" phx-debounce="200" />
  #     <.typeahead_results results={@cities} />
  #   </div>
  #   """
  # end

  # def typeahead_input(assigns) do
  #   ~H"""
  #   """
  # end

  # attr :results, :list, required: true

  # def typeahead_results(assigns) do
  #   ~H"""
  #   <ul class="-mb-2 py-2 text-sm text-gray-800 flex space-y-2 flex-col" id="options" role="listbox">
  #     <li
  #       :if={@results == []}
  #       id="option-none"
  #       role="option"
  #       tabindex="-1"
  #       class="cursor-default select-none rounded-md px-4 py-2 text-xl"
  #     >
  #       <%= gettext("No results") %>
  #     </li>

  #     <span
  #       :for={result <- @results}
  #       phx-click="select"
  #       phx-value-id={result.id}
  #       id={"cities-result-#{result.id}"}
  #     >
  #       <.typeahead_result_item result={result} />
  #     </span>
  #   </ul>
  #   """
  # end

  # def typeahead_result_item(assigns) do
  #   ~H"""
  #   """
  # end

  # @impl true
  # def update(assigns, socket) do
  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_new(
  #      :cities,
  #      Geo.search_cities("ber")
  #    )
  #    |> assign_new(:query, "ber")}
  # end

  # # handle select event
  # @impl true
  # def handle_event("select", %{"id" => id}, socket) do
  #   city = Geo.get_city!(id)
  #   {:noreply, socket |> assign_new(:query, city.name)}
  # end
end
