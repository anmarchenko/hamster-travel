defmodule HamsterTravelWeb.Planning.CityInputTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.GeoFixtures

  alias HamsterTravelWeb.Planning.CityInput

  # Create a simple LiveView to host our component for testing
  defmodule TestFormLive do
    use Phoenix.LiveView

    def render(assigns) do
      ~H"""
      <.form :let={f} for={%{}} as={:test_form} phx-change="validate">
        <.live_component module={CityInput} id="city-input" field={f[:city_id]} label="City" />
      </.form>
      """
    end

    def mount(_params, _session, socket) do
      {:ok, socket}
    end

    def handle_event("validate", _params, socket) do
      {:noreply, socket}
    end
  end

  describe "CityInput component" do
    setup do
      # Import geo data for testing
      geonames_fixture()
      :ok
    end

    test "renders city input field correctly", %{conn: conn} do
      # Render the LiveView that contains our component
      {:ok, view, html} = live_isolated(conn, TestFormLive)

      # Verify the component renders correctly
      assert html =~ "City"
      assert has_element?(view, ".pc-text-input")

      # The test passes if the component renders without errors
      assert html =~ "City"
    end
  end
end
