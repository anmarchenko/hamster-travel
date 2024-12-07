defmodule HamsterTravelWeb.Planning.CityInput do
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo

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
