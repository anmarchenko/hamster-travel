defmodule HamsterTravelWeb.Planning.DestinationForm do
  @moduledoc """
  Destination create/edit form.
  """

  use HamsterTravelWeb, :live_component

  alias HamsterTravelWeb.Planning.CityInput

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id="destination-form" for={@form} phx-target={@myself}>
        <.live_component
          id="destination-form-city-input"
          module={CityInput}
          field={@form[:city_id]}
          label={gettext("City")}
        />
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset =
      {%{}, %{city_id: :string}}
      |> Ecto.Changeset.cast(%{}, [:city_id])

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end
end
