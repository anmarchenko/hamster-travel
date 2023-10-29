defmodule HamsterTravelWeb.Planning.TripForm do
  @moduledoc """
  Live trip create/edit form
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Packing

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form_container>
        <.form for={@form} as={:trip} phx-submit="form_submit" phx-target={@myself}>
          <div class="grid grid-cols-6 gap-x-6">
            <div class="col-span-6">
              <.field
                type="text"
                field={@form[:name]}
                label={gettext("Trip name")}
                required={true}
                autofocus={true}
              />
            </div>
            <div class="col-span-3">
              <.field
                type="date"
                field={@form[:start_date]}
                label={gettext("Start date")}
                required={true}
              />
            </div>
            <div class="col-span-3">
              <.field
                type="date"
                field={@form[:end_date]}
                label={gettext("End date")}
                required={true}
              />
            </div>
          </div>

          <div class="flex justify-between">
            <.button link_type="live_redirect" to={@back_url} color="white">
              <%= gettext("Cancel") %>
            </.button>
            <.button color="primary">
              <%= gettext("Save") %>
            </.button>
          </div>
        </.form>
      </.form_container>
    </div>
    """
  end

  # @impl true
  # def handle_event(
  #       "form_changed",
  #       %{"_target" => ["backpack", "days"], "backpack" => %{"days" => days} = backpack_params},
  #       socket
  #     )
  #     when days != nil and days != "" do
  #   {days, _} = Integer.parse(days)

  #   if days > 1 do
  #     backpack_params
  #     |> Map.put("nights", days - 1)
  #     |> replace_changeset_from_params(socket)
  #   else
  #     {:noreply, socket}
  #   end
  # end

  # @impl true
  # def handle_event(
  #       "form_changed",
  #       %{
  #         "_target" => ["backpack", "nights"],
  #         "backpack" => %{"nights" => nights} = backpack_params
  #       },
  #       socket
  #     )
  #     when nights != nil and nights != "" do
  #   {nights, _} = Integer.parse(nights)

  #   if nights > 0 do
  #     backpack_params
  #     |> Map.put("days", nights + 1)
  #     |> replace_changeset_from_params(socket)
  #   else
  #     {:noreply, socket}
  #   end
  # end

  # @impl true
  # def handle_event(
  #       "form_changed",
  #       _,
  #       socket
  #     ) do
  #   {:noreply, socket}
  # end

  @impl true
  def handle_event("form_submit", %{"trip" => trip_params}, socket) do
    handler = socket.assigns.on_submit
    handler.(socket, trip_params)
  end

  # defp replace_changeset_from_params(params, socket) do
  #   {:noreply, assign(socket, %{changeset: Packing.backpack_changeset(params)})}
  # end
end
