defmodule HamsterTravelWeb.Planning.DestinationForm do
  @moduledoc """
  Destination create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Geo

  alias HamsterTravelWeb.Planning.CityInput

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="destination-form"
        for={@form}
        as={:destination}
        phx-target={@myself}
        phx-submit="form_submit"
      >
        <.live_component
          id="destination-put-destination-id-here-form-city-input"
          module={CityInput}
          field={@form[:city]}
          label={gettext("City")}
        />
        <div class="flex justify-between mt-2">
          <.button color="primary" size="xs">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    [city | _] = Geo.search_cities("lis")

    changeset =
      {%{city: city}, %{city: :map}}
      |> Ecto.Changeset.cast(%{}, [:city])

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset, as: :destination))

    {:ok, socket}
  end

  @impl true
  def handle_event("form_submit", %{"destination" => _destination_params}, socket) do
    {:noreply, socket}
  end
end
