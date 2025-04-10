defmodule HamsterTravelWeb.Planning.DayRangeSelectTest do
  use HamsterTravelWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias HamsterTravelWeb.Planning.DayRangeSelect

  # Create a simple LiveView to host our component for testing
  defmodule TestFormLive do
    use Phoenix.LiveView

    def render(assigns) do
      ~H"""
      <.form :let={f} for={%{"start_day" => 0, "end_day" => 3}} as={:test_form} phx-change="validate">
        <.live_component
          module={DayRangeSelect}
          id="day-range-select"
          start_day_field={f[:start_day]}
          end_day_field={f[:end_day]}
          label="Select Day Range"
          duration={5}
          start_date={~D[2023-01-01]}
        />
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

  describe "DayRangeSelect component" do
    test "renders day range select component correctly", %{conn: conn} do
      # Render the LiveView that contains our component
      {:ok, view, html} =
        live_isolated(conn, TestFormLive)

      # Verify the component renders correctly
      assert html =~ "day-range-select-live-component"
      assert has_element?(view, ".day-range-select-live-component")

      # The test passes if the component renders without errors
      assert html =~ "Select Day Range"

      # start date is present there
      assert html =~ "2023-01-01"

      assert html =~ "01.01"
      assert html =~ "04.01"
    end
  end
end
