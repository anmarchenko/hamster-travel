defmodule HamsterTravelWeb.Planning.ShowTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
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
      assert has_element?(view, "form#destination-form-new-destination-new-0")
      assert has_element?(view, "label", "City")
      assert has_element?(view, "label", "Date range")
      assert has_element?(view, "button", "Save")
      assert has_element?(view, "button", "Cancel")
    end

    test "renders activities tab when selected", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Assert
      assert has_element?(view, "#activities-#{trip.id}")
    end

    test "renders trip page with accommodations", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a trip with accommodations
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          name: "Grand Hotel Vienna",
          link: "https://example.com/hotel",
          address: "123 Main Street, Vienna",
          note: "Great location near the city center",
          start_day: 0,
          end_day: 2,
          expense: %{
            price: Money.new(:EUR, 150),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      # Act
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      # Verify trip name is displayed
      assert html =~ trip.name

      # Verify accommodation details are rendered
      assert html =~ accommodation.name

      # 15000 cents = €150.00, 3 nights (end_day - start_day + 1 = 2 - 0 + 1 = 3), so €50.00 per night
      assert html =~ "€50.00"
      assert html =~ "night"
      assert html =~ "https://example.com/hotel"
      assert html =~ "123 Main Street, Vienna"
      assert html =~ "Great location near the city center"

      # Verify that the accommodation has edit and delete buttons
      assert has_element?(view, "[phx-click='edit']")
      assert has_element?(view, "[phx-click='delete']")

      # Verify that the itinerary tab is active and shows Hotel column
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")
      assert html =~ "Hotel"
    end

    test "renders trip page with transfers", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a trip with transfers
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      transfer =
        transfer_fixture(%{
          trip_id: trip.id,
          transport_mode: "train",
          departure_time: "08:00",
          arrival_time: "12:00",
          note: "Fast train connection",
          vessel_number: "ICE 123",
          carrier: "Deutsche Bahn",
          departure_station: "Berlin Hauptbahnhof",
          arrival_station: "Hamburg Hauptbahnhof",
          day_index: 0,
          expense: %{
            price: Money.new(:EUR, 8900),
            name: "Train ticket",
            trip_id: trip.id
          }
        })

      # Act
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      # Verify trip name is displayed
      assert html =~ trip.name

      # Verify transfer details are rendered
      assert html =~ transfer.vessel_number
      assert html =~ transfer.carrier
      assert html =~ "€8,900.00"
      assert html =~ "08:00"
      assert html =~ "12:00"
      assert html =~ "Fast train connection"

      # Verify that the transfer has edit and delete buttons
      assert has_element?(view, "[phx-click='edit']")
      assert has_element?(view, "[phx-click='delete']")

      # Verify that the itinerary tab is active
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")
    end

    test "shows transfer form when clicking add transfer link", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      # Click the first "Add transfer" link in the first row
      view
      |> element("tr:first-child td a", "Add transfer")
      |> render_click()

      # Assert
      # Verify the transfer form appears with its components
      assert has_element?(view, "form[id^='transfer-form-']")
      assert has_element?(view, "label", "Transport")
      assert has_element?(view, "label", "Departure city")
      assert has_element?(view, "label", "Arrival city")
      assert has_element?(view, "label", "Departure time")
      assert has_element?(view, "label", "Arrival time")
      assert has_element?(view, "label", "Price")
      assert has_element?(view, "button", "Save")
      assert has_element?(view, "button", "Cancel")
    end

    test "shows accommodation form when clicking add accommodation link", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      # Click the first "Add accommodation" link in the first row
      view
      |> element("tr:first-child td a", "Add accommodation")
      |> render_click()

      # Assert
      # Verify the accommodation form appears with its components
      assert has_element?(view, "form[id^='accommodation-form-']")
      assert has_element?(view, "label", "Name")
      assert has_element?(view, "label", "Date range")
      assert has_element?(view, "label", "Price")

      # Fill in the form fields
      view
      |> form("form[id^='accommodation-form-']", %{
        accommodation: %{
          name: "Test Hotel",
          expense: %{
            price: %{
              amount: "120.00",
              currency: "EUR"
            }
          }
        }
      })
      |> render_submit()

      # Verify that the accommodation was created in the database
      accommodations = Planning.list_accommodations(trip)
      assert length(accommodations) == 1

      accommodation = List.first(accommodations)
      assert accommodation.name == "Test Hotel"
      # 120.00 EUR
      assert accommodation.expense.price == Money.new(:EUR, "120.00")
    end

    test "renders accommodation with currency conversion and tooltip", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      # Create accommodation with USD price (different from user currency)
      accommodation =
        accommodation_fixture(%{
          trip_id: trip.id,
          name: "NYC Hotel",
          start_day: 0,
          end_day: 1,
          expense: %{
            # $100.00
            price: Money.new(:USD, 100),
            name: "Hotel booking",
            trip_id: trip.id
          }
        })

      # Act
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      # accommodation name is displayed
      assert html =~ accommodation.name

      # The money display element should have conversion styling (dotted underline and cursor-help)
      assert has_element?(view, "p.border-b.border-dotted.border-gray-400.cursor-help")

      # tooltip contains the original USD amount in title attribute
      assert html =~ "title="
      # "$50.00" per night in the title
      assert html =~ ~r/title="[^"]*\$50\.00/
    end
  end
end
