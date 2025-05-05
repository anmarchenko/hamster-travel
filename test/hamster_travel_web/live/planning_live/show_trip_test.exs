defmodule HamsterTravelWeb.Planning.ShowTripTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Geo
  alias HamsterTravelWeb.Cldr

  describe "Show trip page" do
    test "renders trip page with empty trip and known dates", %{conn: conn} do
      # Arrange
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create an empty trip
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      # Visit the trip page
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      # Assert the page renders successfully and displays the trip name
      assert html =~ trip.name

      # Verify that the tabs are rendered
      assert has_element?(view, "a", "Transfers and hotels")
      assert has_element?(view, "a", "Activities")

      # Verify that the itinerary tab is active by default
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")

      # Verify that dates are displayed
      assert html =~ Cldr.date_with_weekday(trip.start_date)
      assert html =~ Cldr.date_with_weekday(trip.end_date)
    end

    test "renders trip page with empty trip and unknown dates", %{conn: conn} do
      # Arrange
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create an empty trip
      trip =
        trip_fixture(%{
          name: "Venice idea",
          author_id: user.id,
          status: "0_draft",
          dates_unknown: true,
          start_date: nil,
          end_date: nil,
          duration: 2
        })

      # Act
      # Visit the trip page
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      # Assert the page renders successfully and displays the trip name
      assert html =~ trip.name

      # Verify that the tabs are rendered
      assert has_element?(view, "a", "Transfers and hotels")
      assert has_element?(view, "a", "Activities")

      # Verify that the itinerary tab is active by default
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")

      # Verify that dates are displayed
      assert html =~ "Day 1"
      assert html =~ "Day 2"
      refute html =~ "Day 3"
    end

    test "renders trip page with destinations", %{conn: conn} do
      # Arrange
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create an empty trip
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})
      destination = destination_fixture(%{trip_id: trip.id, start_day: 0, end_day: 1})
      destination = Map.put(destination, :city, Geo.get_city!(destination.city_id))

      # Act
      # Visit the trip page
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      # Assert the page renders successfully and displays the trip name
      assert html =~ trip.name

      # Verify that the tabs are rendered
      assert has_element?(view, "a", "Transfers and hotels")
      assert has_element?(view, "a", "Activities")

      # Verify that the itinerary tab is active by default
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")

      # Verify that destination is present
      assert html =~ destination.city.name
    end

    test "shows destination form when clicking add destination link", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      # Click the first "Add city" link in the first row
      view
      |> element("tr:first-child td a", "Add city")
      |> render_click()

      # Assert
      # Verify the form appears with its components
      assert has_element?(view, "form#destination-form")
      assert has_element?(view, "label", "City")
      assert has_element?(view, "label", "Date range")
      assert has_element?(view, "button", "Save")
      assert has_element?(view, "button", "Cancel")
    end
  end
end
