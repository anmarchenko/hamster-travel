defmodule HamsterTravelWeb.Planning.CityInput do
  use HamsterTravelWeb, :live_component

  import LiveSelect

  alias HamsterTravel.Geo

  attr :field, Phoenix.HTML.FormField, required: true
  attr :validated_field, Phoenix.HTML.FormField, required: false
  attr :label, :string, required: true
  attr :trip_cities, :list, default: []

  @impl true
  def render(%{field: field} = assigns) do
    field_with_errors = if assigns[:validated_field], do: assigns.validated_field, else: field
    errors = if used_input?(field), do: field_with_errors.errors, else: []

    assigns =
      assigns
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))

    ~H"""
    <div>
      <.label for={@field.id}>{@label}</.label>
      <.live_select
        id={"#{@id}-live-select"}
        field={@field}
        value_mapper={&value_mapper/1}
        phx-target={@myself}
        text_input_class="pc-text-input"
        dropdown_class="absolute rounded-md shadow z-50 bg-white dark:bg-zinc-900 dark:text-zinc-300 inset-x-0 top-full max-h-32 overflow-y-scroll w-max max-w-[330px] sm:max-w-md"
        active_option_class="font-bold bg-gray-200 dark:bg-zinc-700"
        option_class="rounded px-4 py-2 md:py-1"
        update_min_len={2}
        options={initial_options(@trip_cities)}
      >
        <:option :let={option}>
          <.inline>
            <.flag size={20} country={option.value.country} /> {option.label}
          </.inline>
        </:option>
      </.live_select>

      <.field_error :for={msg <- @errors}>{msg}</.field_error>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:trip_cities, fn -> [] end)

    {:ok, socket}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    trip_cities = Map.get(socket.assigns, :trip_cities, [])
    cities = get_cities_for_search(text, trip_cities)

    send_update(LiveSelect.Component, id: live_select_id, options: cities)

    {:noreply, socket}
  end

  def process_selected_value_on_submit(params, field_name) do
    city_input_value = Map.get(params, field_name)

    city_json =
      if city_input_value != nil && city_input_value != "",
        do: Jason.decode!(city_input_value),
        else: %{}

    city_id = Map.get(city_json, "id")
    city = if city_id != nil, do: Geo.get_city(city_id), else: nil

    params
    |> Map.put(field_name <> "_id", city_id)
    |> Map.put(field_name, city)
  end

  defp value_mapper(nil), do: nil
  defp value_mapper(""), do: nil

  defp value_mapper(city) do
    %{
      label: Geo.city_text(city),
      value: %{
        id: city.id,
        country: city.country.iso
      }
    }
  end

  defp initial_options([]), do: []

  defp initial_options(trip_cities) do
    trip_cities
    |> Enum.map(&value_mapper/1)
  end

  defp get_cities_for_search(text, []) do
    search_cities(text)
  end

  defp get_cities_for_search(text, trip_cities) do
    search_results = search_cities(text)
    trip_city_ids = Enum.map(trip_cities, & &1.id)

    # Filter search results that match trip_cities
    matching_trip_cities =
      search_results
      |> Enum.filter(fn option ->
        option.value.id in trip_city_ids
      end)

    other_results =
      Enum.reject(search_results, fn option ->
        option.value.id in trip_city_ids
      end)

    matching_trip_cities ++ other_results
  end

  defp search_cities(text) do
    text
    |> Geo.search_cities()
    |> Enum.map(&value_mapper/1)
  end
end
