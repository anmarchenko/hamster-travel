defmodule HamsterTravelWeb.Planning.CityInput do
  use HamsterTravelWeb, :live_component

  import LiveSelect

  alias HamsterTravel.Geo

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true

  @impl true
  def render(%{field: field} = assigns) do
    # errors = if used_input?(field), do: field.errors, else: []

    # assigns =
    #   assigns
    #   |> assign(:errors, Enum.map([], &translate_error(&1)))

    ~H"""
    <div>
      <.label for={@field.id}><%= @label %></.label>
      <.live_select
        field={@field}
        value_mapper={&value_mapper/1}
        phx-target={@myself}
        text_input_class="pc-text-input"
        dropdown_class="absolute rounded-md shadow z-50 bg-white dark:bg-zinc-900 dark:text-zinc-300 inset-x-0 top-full max-h-32 overflow-y-scroll w-max max-w-[330px] sm:max-w-md"
        active_option_class="font-bold bg-gray-200 dark:bg-zinc-700"
        option_class="rounded px-4 py-2 md:py-1"
        update_min_len={2}
      >
        <:option :let={option}>
          <.inline>
            <.flag size={16} country={option.value.country} />
            <%= option.label %>
          </.inline>
        </:option>
      </.live_select>

      <%!-- <.field_error :for={msg <- @errors}>{msg}</.field_error> --%>
    </div>
    """
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    cities =
      text
      |> Geo.search_cities()
      |> Enum.map(&value_mapper/1)

    send_update(LiveSelect.Component, id: live_select_id, options: cities)

    {:noreply, socket}
  end

  defp value_mapper(city) do
    %{
      label: Geo.city_text(city),
      value: %{
        id: city.id,
        country: city.country.iso
      }
    }
  end
end
