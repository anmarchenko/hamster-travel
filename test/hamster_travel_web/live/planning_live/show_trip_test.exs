defmodule HamsterTravelWeb.Planning.ShowTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.GeoFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.TripCover
  alias HamsterTravel.Repo
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

      # Verify copy button is displayed
      assert html =~ "Make a copy"

      # Verify that the tabs are rendered
      assert has_element?(view, "a", "Transfers and hotels")
      assert has_element?(view, "a", "Activities")
      assert has_element?(view, "a", "Notes")

      # Verify that the itinerary tab is active by default
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")

      # Verify that dates are displayed
      assert html =~ Cldr.date_with_weekday(trip.start_date)
      assert html =~ Cldr.date_with_weekday(trip.end_date)
    end

    test "shows cover upload dropzone for editors", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      assert has_element?(view, "form#cover-upload-form")
      assert has_element?(view, "[data-cover-dropzone]")
    end

    test "renders cover image when trip has a cover", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      trip =
        trip
        |> Ecto.Changeset.change(%{
          cover: %{file_name: "cover.jpg", updated_at: DateTime.utc_now()}
        })
        |> Repo.update!()

      {:ok, _view, html} = live(conn, ~p"/trips/#{trip.slug}")

      assert html =~ TripCover.url({trip.cover, trip}, :hero)
    end

    test "deletes trip from the trip page", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, trip} =
        Planning.create_trip(
          %{
            name: "Delete me",
            dates_unknown: false,
            start_date: ~D[2023-06-12],
            end_date: ~D[2023-06-14],
            currency: "EUR",
            status: "1_planned",
            private: false,
            people_count: 2
          },
          user
        )

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      view
      |> element("[phx-click='delete_trip']")
      |> render_click()

      # Assert
      assert_redirect(view, ~p"/plans")
      assert Planning.get_trip(trip.id) == nil
    end

    test "hides delete button for non-authors", %{conn: conn} do
      # Arrange
      author = user_fixture()
      other_user = user_fixture()
      conn = log_in_user(conn, other_user)

      {:ok, trip} =
        Planning.create_trip(
          %{
            name: "Shared trip",
            dates_unknown: false,
            start_date: ~D[2023-06-12],
            end_date: ~D[2023-06-14],
            currency: "EUR",
            status: "1_planned",
            private: false,
            people_count: 2
          },
          author
        )

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      # Assert
      refute has_element?(view, "[phx-click='delete_trip']")
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
      assert has_element?(view, "a", "Notes")

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
      assert has_element?(view, "a", "Notes")

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

    test "renders notes tab when selected", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, day_note} = Planning.create_note(trip, %{title: "Day note", day_index: 0})
      {:ok, unassigned_note} = Planning.create_note(trip, %{title: "Trip report", day_index: nil})

      # Act
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}?tab=notes")

      # Assert
      assert has_element?(view, "#notes-#{trip.id}")
      assert html =~ day_note.title
      assert html =~ unassigned_note.title
    end

    test "shows note form when adding an unassigned note", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=notes")

      view
      |> element("#note-new-unassigned a", "Add note")
      |> render_click()

      # Assert
      assert has_element?(view, "form#note-form-new-note-new-unassigned")
    end

    test "moves note to a new day via drag event", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", duration: 3})
      {:ok, note} = Planning.create_note(trip, %{title: "Move me", day_index: 0})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=notes")

      render_hook(view, "move_note", %{
        "note_id" => Integer.to_string(note.id),
        "new_day_index" => "1",
        "position" => 0
      })

      # Assert
      assert Planning.get_note!(note.id).day_index == 1
    end

    test "reorders unassigned notes via drag event", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})
      {:ok, note1} = Planning.create_note(trip, %{title: "First", day_index: nil})
      {:ok, note2} = Planning.create_note(trip, %{title: "Second", day_index: nil})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=notes")

      render_hook(view, "reorder_note", %{
        "note_id" => Integer.to_string(note2.id),
        "position" => 0
      })

      # Assert
      [first | _] = Planning.list_notes(trip)
      assert first.id == note2.id
      assert note1.id != note2.id
    end

    test "renders day-bound notes on activities tab only", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, day_note} = Planning.create_note(trip, %{title: "Day note", day_index: 0})
      {:ok, unassigned_note} = Planning.create_note(trip, %{title: "Trip report", day_index: nil})

      {:ok, outside_note} =
        Planning.create_note(trip, %{title: "Outside note", day_index: trip.duration + 1})

      # Act
      {:ok, _view, html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Assert
      assert html =~ day_note.title
      assert html =~ outside_note.title
      refute html =~ unassigned_note.title
    end

    test "deletes outside items from activities tab", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip =
        trip_fixture(%{
          author_id: user.id,
          status: "0_draft",
          dates_unknown: true,
          duration: 1
        })

      geonames_fixture()
      city = Geo.find_city_by_geonames_id("2950159")

      {:ok, inside_destination} =
        Planning.create_destination(trip, %{city_id: city.id, start_day: 0, end_day: 0})

      {:ok, outside_destination} =
        Planning.create_destination(trip, %{city_id: city.id, start_day: 2, end_day: 2})

      {:ok, inside_activity} =
        Planning.create_activity(trip, %{
          name: "Inside activity",
          day_index: 0,
          priority: 2,
          expense: %{price: Money.new(:EUR, 1000), name: "Inside activity", trip_id: trip.id}
        })

      {:ok, outside_activity} =
        Planning.create_activity(trip, %{
          name: "Outside activity",
          day_index: 2,
          priority: 2,
          expense: %{price: Money.new(:EUR, 1000), name: "Outside activity", trip_id: trip.id}
        })

      {:ok, inside_day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Inside expense",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 1200), name: "Inside expense", trip_id: trip.id}
        })

      {:ok, outside_day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Outside expense",
          day_index: 2,
          expense: %{price: Money.new(:EUR, 1200), name: "Outside expense", trip_id: trip.id}
        })

      {:ok, inside_note} = Planning.create_note(trip, %{title: "Inside note", day_index: 0})
      {:ok, outside_note} = Planning.create_note(trip, %{title: "Outside note", day_index: 2})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      view
      |> element("[phx-click='delete_outside_activities']")
      |> render_click()

      # Assert
      destinations = Planning.list_destinations(trip)
      refute Enum.any?(destinations, &(&1.id == outside_destination.id))
      assert Enum.any?(destinations, &(&1.id == inside_destination.id))

      activities = Planning.list_activities(trip)
      refute Enum.any?(activities, &(&1.id == outside_activity.id))
      assert Enum.any?(activities, &(&1.id == inside_activity.id))

      day_expenses = Planning.list_day_expenses(trip)
      refute Enum.any?(day_expenses, &(&1.id == outside_day_expense.id))
      assert Enum.any?(day_expenses, &(&1.id == inside_day_expense.id))

      notes = Planning.list_notes(trip)
      refute Enum.any?(notes, &(&1.id == outside_note.id))
      assert Enum.any?(notes, &(&1.id == inside_note.id))
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

    test "shows user's home city in transfer city default options", %{conn: conn} do
      geonames_fixture()
      home_city = Geo.find_city_by_geonames_id("2950159")
      home_city_name = home_city.name

      user = user_fixture(%{home_city_id: home_city.id})
      conn = log_in_user(conn, user)
      trip = trip_fixture(user, %{status: "0_draft"})

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      view
      |> element("tr:first-child td a", "Add transfer")
      |> render_click()

      view
      |> element("input[name='transfer[departure_city_text_input]']")
      |> render_click()

      assert render(view) =~ home_city_name
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
      assert has_element?(view, "div.border-b.border-dotted.border-gray-400.cursor-help")

      # tooltip contains the original USD amount
      # It is now rendered in a hidden div that appears on hover
      assert has_element?(view, "div.hidden.group-hover\\:block", "$50.00")
    end

    test "uses current user default currency for trip budget display", %{conn: conn} do
      user = user_fixture(%{default_currency: "USD"})
      conn = log_in_user(conn, user)

      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, _expense} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 100), name: "Budget item"})

      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      assert html =~ "$110.00"
      assert has_element?(view, "div.hidden.group-hover\\:block", "€100.00")
    end

    test "renders trip page with activities", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      _ =
        activity_fixture(%{
          trip_id: trip.id,
          name: "Louvre Museum",
          # Must see
          priority: 3,
          day_index: 0,
          expense: %{
            price: Money.new(:EUR, 2000),
            name: "Louvre Ticket",
            trip_id: trip.id
          }
        })

      # Act
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Assert

      assert html =~ "Louvre Museum"
      assert html =~ "€2,000.00"

      # Verify priority styling (bold for priority 3)
      assert has_element?(view, ".font-bold", "Louvre Museum")

      # Verify edit/delete buttons
      assert has_element?(view, "[phx-click='edit']")
      assert has_element?(view, "[phx-click='delete']")
    end

    test "shows activity form when clicking add activity button", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Click the add activity button for day 0

      view
      |> element("#activity-new-0 [phx-click='add_activity']")
      |> render_click()

      # Assert

      assert has_element?(view, "form[id*='activity-form-new-activity-new-0']")
      assert has_element?(view, "label", "Activity Name")
      assert has_element?(view, "label", "Priority")
      assert has_element?(view, "label", "Price")
    end

    test "can create activity via form", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Open form

      view
      |> element("#activity-new-0 [phx-click='add_activity']")
      |> render_click()

      # Submit form

      view
      |> form("form[id*='activity-form-new-activity-new-0']", %{
        activity: %{
          name: "Eiffel Tower",
          priority: "3",
          day_index: "0",
          expense: %{
            price: %{
              amount: "25.00",
              currency: "EUR"
            }
          }
        }
      })
      |> render_submit()

      # Assert

      assert has_element?(view, "div", "Eiffel Tower")
      assert has_element?(view, ".font-bold", "Eiffel Tower")

      # Verify DB
      activities = Planning.list_activities(trip)
      assert length(activities) == 1

      activity = List.first(activities)
      assert activity.name == "Eiffel Tower"
      assert activity.priority == 3
    end

    test "shows day expense form when clicking add expense button", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Click the add expense button for day 0
      view
      |> element("#day-expense-new-0 [phx-click='add_day_expense']")
      |> render_click()

      # Assert

      assert has_element?(view, "form[id*='day-expense-form-new-day-expense-new-0']")
      assert has_element?(view, "label", "Name")
      assert has_element?(view, "label", "Price")
    end

    test "can create day expense via form", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Open form
      view
      |> element("#day-expense-new-0 [phx-click='add_day_expense']")
      |> render_click()

      # Submit form
      view
      |> form("form[id*='day-expense-form-new-day-expense-new-0']", %{
        day_expense: %{
          name: "Metro card",
          day_index: "0",
          expense: %{
            price: %{
              amount: "12.00",
              currency: "EUR"
            }
          }
        }
      })
      |> render_submit()

      # Assert

      assert has_element?(view, "div", "Metro card")

      # Verify DB
      day_expenses = Planning.list_day_expenses(trip)
      assert length(day_expenses) == 1

      day_expense = List.first(day_expenses)
      assert day_expense.name == "Metro card"
    end

    test "shows food expense summary", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})
      trip = Planning.get_trip!(trip.id)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      assert has_element?(view, "#food-expense-#{trip.food_expense.id}")
      assert render(view) =~ "Food expenses"
    end

    test "can edit food expense via form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})
      trip = Planning.get_trip!(trip.id)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      view
      |> element("#food-expense-#{trip.food_expense.id} [phx-click='edit']")
      |> render_click()

      assert has_element?(view, "form#food-expense-form-#{trip.food_expense.id}")

      view
      |> form("form#food-expense-form-#{trip.food_expense.id}", %{
        food_expense: %{
          price_per_day: %{amount: "10.00", currency: "EUR"},
          days_count: "2",
          people_count: "3"
        }
      })
      |> render_submit()

      updated = Planning.get_food_expense!(trip.food_expense.id)

      expected =
        Money.new(:EUR, "10.00")
        |> Money.mult!(2)
        |> Money.mult!(3)

      assert updated.expense.price == expected
    end

    test "recalculates budget when food expense changes", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, _expense} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 40), name: "Souvenirs"})

      trip = Planning.get_trip!(trip.id)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      assert render(view) =~ "€40.00"

      {:ok, updated_food_expense} =
        Planning.update_food_expense(trip.food_expense, %{
          price_per_day: Money.new(:EUR, 10),
          days_count: 2,
          people_count: 3
        })

      assert updated_food_expense.expense.price == Money.new(:EUR, 60)
      assert_eventually_contains(view, "€100.00")
    end

    test "recalculates budget for standalone expense create/update/delete events", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      assert render(view) =~ "€0.00"

      {:ok, created_expense} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 40), name: "Souvenirs"})

      assert created_expense.price == Money.new(:EUR, 40)
      assert_eventually_contains(view, "€40.00")

      {:ok, updated_expense} =
        Planning.update_expense(created_expense, %{price: Money.new(:EUR, 90)})

      assert updated_expense.price == Money.new(:EUR, 90)
      assert_eventually_contains(view, "€90.00")

      {:ok, deleted_expense} = Planning.delete_expense(updated_expense)

      assert deleted_expense.id == updated_expense.id
      assert_eventually_contains(view, "€0.00")
    end

    test "recalculates budget for all expense-bearing entities", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, _base_expense} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 10), name: "Base"})

      {:ok, accommodation} =
        Planning.create_accommodation(trip, %{
          name: "Hotel",
          start_day: 0,
          end_day: 0,
          expense: %{price: Money.new(:EUR, 20), name: "Hotel", trip_id: trip.id}
        })

      geonames_fixture()
      berlin = Geo.find_city_by_geonames_id("2950159")
      hamburg = Geo.find_city_by_geonames_id("2911298")

      {:ok, transfer} =
        Planning.create_transfer(trip, %{
          transport_mode: "train",
          departure_city_id: berlin.id,
          arrival_city_id: hamburg.id,
          departure_time: "08:00",
          arrival_time: "12:00",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 30), name: "Train", trip_id: trip.id}
        })

      {:ok, activity} =
        Planning.create_activity(trip, %{
          name: "Museum",
          day_index: 0,
          priority: 2,
          expense: %{price: Money.new(:EUR, 40), name: "Museum", trip_id: trip.id}
        })

      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Snacks",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 50), name: "Snacks", trip_id: trip.id}
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      assert render(view) =~ "€150.00"

      {:ok, updated_accommodation} =
        Planning.update_accommodation(accommodation, %{
          expense: %{id: accommodation.expense.id, price: Money.new(:EUR, 25)}
        })

      assert updated_accommodation.expense.price == Money.new(:EUR, 25)
      assert_eventually_contains(view, "€155.00")

      {:ok, updated_transfer} =
        Planning.update_transfer(transfer, %{
          expense: %{id: transfer.expense.id, price: Money.new(:EUR, 35)}
        })

      assert updated_transfer.expense.price == Money.new(:EUR, 35)
      assert_eventually_contains(view, "€160.00")

      {:ok, updated_activity} =
        Planning.update_activity(activity, %{
          expense: %{id: activity.expense.id, price: Money.new(:EUR, 45)}
        })

      assert updated_activity.expense.price == Money.new(:EUR, 45)
      assert_eventually_contains(view, "€165.00")

      {:ok, updated_day_expense} =
        Planning.update_day_expense(day_expense, %{
          expense: %{id: day_expense.expense.id, price: Money.new(:EUR, 55)}
        })

      assert updated_day_expense.expense.price == Money.new(:EUR, 55)
      assert_eventually_contains(view, "€170.00")

      {:ok, deleted_day_expense} = Planning.delete_day_expense(updated_day_expense)

      assert deleted_day_expense.id == updated_day_expense.id
      assert_eventually_contains(view, "€115.00")

      {:ok, created_day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Coffee",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 20), name: "Coffee", trip_id: trip.id}
        })

      assert created_day_expense.expense.price == Money.new(:EUR, 20)
      assert_eventually_contains(view, "€135.00")
    end

    test "can move activity via drag and drop", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", duration: 3})

      activity =
        activity_fixture(%{
          trip_id: trip.id,
          day_index: 0,
          name: "Morning Walk"
        })

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Simulate drag and drop via hook event
      render_hook(view, "move_activity", %{
        "activity_id" => to_string(activity.id),
        "new_day_index" => 1,
        "position" => 0
      })

      # Assert

      updated_activity = Planning.get_activity!(activity.id)
      assert updated_activity.day_index == 1
    end

    test "can reorder activity within day", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      # Create two activities on same day
      a1 = activity_fixture(%{trip_id: trip.id, day_index: 0, name: "First"})
      a2 = activity_fixture(%{trip_id: trip.id, day_index: 0, name: "Second"})

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Move "First" (a1) to position 1 (after "Second")
      render_hook(view, "reorder_activity", %{
        "activity_id" => to_string(a1.id),
        "position" => 1
      })

      # Assert

      # Need to reload to check order
      activities = Planning.activities_for_day(0, Planning.list_activities(trip))

      [first, second] = activities
      assert first.id == a2.id
      assert second.id == a1.id
    end
  end

  defp assert_eventually_contains(view, expected_text, attempts_left \\ 20)

  defp assert_eventually_contains(view, expected_text, attempts_left) when attempts_left > 0 do
    html = render(view)

    if html =~ expected_text do
      assert html =~ expected_text
    else
      Process.sleep(20)
      assert_eventually_contains(view, expected_text, attempts_left - 1)
    end
  end

  defp assert_eventually_contains(_view, expected_text, 0) do
    flunk("expected rendered LiveView to include #{inspect(expected_text)}")
  end
end
