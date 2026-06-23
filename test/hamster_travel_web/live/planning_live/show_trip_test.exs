defmodule HamsterTravelWeb.Planning.ShowTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.GeoFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.{Trip, TripCover}
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
      assert has_element?(view, "a[href=\"/trips/#{trip.slug}/export.pdf\"]", "Export to PDF")

      # Verify that the tabs are rendered
      assert has_element?(view, "a", "Transfers and hotels")
      assert has_element?(view, "a", "Activities")
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Notes")

      # Verify that the itinerary tab is active by default
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")

      # Verify that dates are displayed
      assert html =~ "12.06 - 14.06.2023"
      assert html =~ Cldr.date_with_weekday(trip.start_date)
      assert html =~ Cldr.date_with_weekday(trip.end_date)
    end

    test "renders full years in header when trip dates cross year", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip =
        trip_fixture(%{
          author_id: user.id,
          start_date: ~D[2025-12-31],
          end_date: ~D[2026-01-02]
        })

      {:ok, _view, html} = live(conn, ~p"/trips/#{trip.slug}")

      assert html =~ "31.12.2025 - 02.01.2026"
    end

    test "uses return_to for mobile back and preserves it in tab links", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "1_planned"})

      return_to = "/plans?page=2&q=Searchable"
      encoded_return_to = URI.encode_www_form(return_to)

      {:ok, _view, html} = live(conn, "/trips/#{trip.slug}?return_to=#{encoded_return_to}")

      assert html =~ ~s(href="/plans?page=2&amp;q=Searchable")

      assert html =~
               ~s(href="/trips/#{trip.slug}?tab=activities&amp;return_to=%2Fplans%3Fpage%3D2%26q%3DSearchable")

      assert html =~
               ~s(href="/trips/#{trip.slug}?tab=budget&amp;return_to=%2Fplans%3Fpage%3D2%26q%3DSearchable")
    end

    test "ignores unsafe return_to values", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "1_planned"})

      unsafe_return_to = URI.encode_www_form("https://example.com/plans?page=2")

      {:ok, _view, html} = live(conn, "/trips/#{trip.slug}?return_to=#{unsafe_return_to}")

      assert html =~ ~s(href="/plans")
      refute html =~ "example.com"
    end

    test "hides empty mobile itinerary section headers but keeps add links", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}")

      section_headers =
        html
        |> Floki.parse_document!()
        |> Floki.find("#trip-itinerary .text-xs.font-semibold.uppercase")

      assert section_headers == []
      assert has_element?(view, "#trip-itinerary a", "Add city")
      assert has_element?(view, "#trip-itinerary a", "Add transfer")
      assert has_element?(view, "#trip-itinerary a", "Add accommodation")
    end

    test "shows mobile itinerary section header when section has items", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      transfer_fixture(%{trip_id: trip.id, day_index: 0, vessel_number: "ICE 123"})

      {:ok, _view, html} = live(conn, ~p"/trips/#{trip.slug}")

      header_text =
        html
        |> Floki.parse_document!()
        |> Floki.find("#trip-itinerary .text-xs.font-semibold.uppercase")
        |> Floki.text(sep: " ")

      assert header_text =~ "Transfers"
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
      return_to = "/plans?page=2&q=Delete"

      {:ok, view, _html} =
        live(conn, "/trips/#{trip.slug}?return_to=#{URI.encode_www_form(return_to)}")

      view
      |> element("[phx-click='delete_trip']")
      |> render_click()

      # Assert
      assert_redirect(view, return_to)
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

    test "does not render trip items as draggable for non-participants", %{conn: conn} do
      author = user_fixture()
      other_user = user_fixture()
      conn = log_in_user(conn, other_user)

      {:ok, trip} =
        Planning.create_trip(
          %{
            name: "Readonly shared trip",
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
          expense: %{price: Money.new(:EUR, 8900), name: "Train ticket", trip_id: trip.id}
        })

      {:ok, _activity} =
        Planning.create_activity(trip, %{
          name: "Museum",
          day_index: 0,
          priority: 2,
          expense: %{price: Money.new(:EUR, 2000), name: "Museum ticket", trip_id: trip.id}
        })

      {:ok, _day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Coffee",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 500), name: "Coffee", trip_id: trip.id}
        })

      {:ok, itinerary_view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      assert has_element?(itinerary_view, "#trip-itinerary[data-can-edit='false']")
      refute has_element?(itinerary_view, ".draggable-transfer")

      html =
        render_hook(itinerary_view, "move_transfer", %{
          "transfer_id" => to_string(transfer.id),
          "new_day_index" => 1
        })

      assert html =~ "Only trip participants can edit this trip."
      refute html =~ "Failed to move transfer"

      {:ok, activities_view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      assert has_element?(activities_view, "#activities-#{trip.id}[data-can-edit='false']")
      refute has_element?(activities_view, ".draggable-activity")
      refute has_element?(activities_view, ".draggable-day-expense")
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
      assert has_element?(view, "a", "Budget")
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
      assert has_element?(view, "a", "Budget")
      assert has_element?(view, "a", "Notes")

      # Verify that the itinerary tab is active by default
      assert has_element?(view, "a.pc-tab__underline--is-active", "Transfers and hotels")

      # Verify that destination is present
      assert html =~ destination.city.name

      {:ok, _view, activities_html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      assert activities_html =~ "flex flex-col gap-y-1 sm:flex-row sm:gap-x-4 sm:gap-y-0"
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

    test "budget tab groups existing source expenses and edits source amounts only", %{
      conn: conn
    } do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, accommodation} =
        Planning.create_accommodation(trip, %{
          name: "Grand Hotel Vienna",
          start_day: 0,
          end_day: 1,
          expense: %{price: Money.new(:EUR, 20), name: "Hotel", trip_id: trip.id}
        })

      {:ok, zero_accommodation} =
        Planning.create_accommodation(trip, %{
          name: "Free couch",
          start_day: 1,
          end_day: 1,
          expense: %{price: Money.new(:EUR, 0), name: "Free couch", trip_id: trip.id}
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
          vessel_number: "ICE 123",
          carrier: "DB",
          day_index: 1,
          expense: %{price: Money.new(:EUR, 30), name: "Train", trip_id: trip.id}
        })

      {:ok, zero_transfer} =
        Planning.create_transfer(trip, %{
          transport_mode: "bus",
          departure_city_id: hamburg.id,
          arrival_city_id: berlin.id,
          departure_time: "14:00",
          arrival_time: "18:00",
          vessel_number: "FREE 1",
          carrier: "ZeroBus",
          day_index: 1,
          expense: %{price: Money.new(:EUR, 0), name: "Free bus", trip_id: trip.id}
        })

      {:ok, activity} =
        Planning.create_activity(trip, %{
          name: "Museum",
          day_index: 1,
          priority: 2,
          expense: %{price: Money.new(:EUR, 40), name: "Museum", trip_id: trip.id}
        })

      {:ok, zero_activity} =
        Planning.create_activity(trip, %{
          name: "Free walking tour",
          day_index: 1,
          priority: 2,
          expense: %{price: Money.new(:EUR, 0), name: "Free walking tour", trip_id: trip.id}
        })

      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Snacks",
          day_index: 1,
          expense: %{price: Money.new(:EUR, 50), name: "Snacks", trip_id: trip.id}
        })

      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      assert has_element?(view, "#budget-#{trip.id}")

      budget_section_headers =
        html
        |> Floki.parse_document!()
        |> Floki.find("#budget-#{trip.id} .text-xs.font-semibold.uppercase")
        |> Floki.text(sep: " ")

      assert budget_section_headers =~ "Hotels"
      assert budget_section_headers =~ "Transfers"
      assert budget_section_headers =~ "Activities"
      assert budget_section_headers =~ "Day expenses"
      assert html =~ "Hotels"
      assert html =~ "Grand Hotel Vienna, Day 1-2"
      refute html =~ "Free couch"
      assert html =~ "Transfers"
      assert html =~ "Berlin → Hamburg, DB ICE 123"
      assert html =~ "Activities"
      assert html =~ "Museum"
      refute html =~ "Hamburg → Berlin, ZeroBus FREE 1"
      refute html =~ "Free walking tour"
      assert html =~ "Day expenses"
      assert html =~ "Snacks"
      refute has_element?(view, "#day-expense-new-0")
      assert has_element?(view, "#day-expense-new-1")
      refute has_element?(view, "#day-expense-new-2")
      refute has_element?(view, "#budget-#{trip.id} a", "Add accommodation")
      refute has_element?(view, "#budget-#{trip.id} a", "Add transfer")
      refute has_element?(view, "#budget-#{trip.id} a", "Add activity")

      refute has_element?(
               view,
               "#budget-expense-hotel-#{accommodation.expense.id} [phx-click='delete']"
             )

      refute has_element?(view, "#budget-expense-hotel-#{zero_accommodation.expense.id}")

      assert has_element?(
               view,
               "#budget-expense-hotel-#{accommodation.expense.id} [class*='flex-1'] [phx-click='edit']"
             )

      refute has_element?(
               view,
               "#budget-expense-hotel-#{accommodation.expense.id} [class*='sm:w-44'] [phx-click='edit']"
             )

      refute has_element?(
               view,
               "#budget-expense-transfer-#{transfer.expense.id} [phx-click='delete']"
             )

      refute has_element?(view, "#budget-expense-transfer-#{zero_transfer.expense.id}")

      refute has_element?(
               view,
               "#budget-expense-activity-#{activity.expense.id} [phx-click='delete']"
             )

      refute has_element?(view, "#budget-expense-activity-#{zero_activity.expense.id}")

      assert has_element?(view, "[data-day-expense-id='#{day_expense.id}'] [phx-click='delete']")

      assert has_element?(
               view,
               "[data-day-expense-id='#{day_expense.id}'] [class*='flex-1'] [phx-click='delete']"
             )

      refute has_element?(
               view,
               "[data-day-expense-id='#{day_expense.id}'] [class*='sm:w-44'] [phx-click='delete']"
             )

      Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "planning:#{trip.id}")

      view
      |> element("#budget-expense-hotel-#{accommodation.expense.id} [phx-click='edit']")
      |> render_click()

      assert has_element?(view, "form#budget-expense-form-hotel-#{accommodation.expense.id}")
      refute render(view) =~ "Address"

      view
      |> form("form#budget-expense-form-hotel-#{accommodation.expense.id}", %{
        expense: %{price: %{amount: "25.00", currency: "EUR"}}
      })
      |> render_submit()

      assert_receive {[:accommodation, :updated], %{value: updated_accommodation}}
      assert updated_accommodation.id == accommodation.id
      assert updated_accommodation.expense.price == Money.new(:EUR, "25.00")

      updated_expense = Planning.get_expense!(accommodation.expense.id)
      assert updated_expense.price == Money.new(:EUR, "25.00")
      assert_eventually_contains(view, "€145.00")

      view
      |> element("#budget-expense-transfer-#{transfer.expense.id} [phx-click='edit']")
      |> render_click()

      view
      |> form("form#budget-expense-form-transfer-#{transfer.expense.id}", %{
        expense: %{price: %{amount: "35.00", currency: "EUR"}}
      })
      |> render_submit()

      assert_receive {[:transfer, :updated], %{value: updated_transfer}}
      assert updated_transfer.id == transfer.id
      assert updated_transfer.expense.price == Money.new(:EUR, "35.00")
      assert_eventually_contains(view, "€150.00")

      view
      |> element("#budget-expense-activity-#{activity.expense.id} [phx-click='edit']")
      |> render_click()

      view
      |> form("form#budget-expense-form-activity-#{activity.expense.id}", %{
        expense: %{price: %{amount: "45.00", currency: "EUR"}}
      })
      |> render_submit()

      assert_receive {[:activity, :updated], %{value: updated_activity}}
      assert updated_activity.id == activity.id
      assert updated_activity.expense.price == Money.new(:EUR, "45.00")
      assert_eventually_contains(view, "€155.00")

      view
      |> element("[data-day-expense-id='#{day_expense.id}'] [phx-click='edit']")
      |> render_click()

      view
      |> form("form[id*='day-expense-form-#{day_expense.id}']", %{
        day_expense: %{
          name: "Snacks",
          day_index: "1",
          expense: %{
            id: day_expense.expense.id,
            price: %{amount: "55.00", currency: "EUR"}
          }
        }
      })
      |> render_submit()

      assert_receive {[:day_expense, :updated], %{value: updated_day_expense}}
      assert updated_day_expense.id == day_expense.id
      assert updated_day_expense.expense.price == Money.new(:EUR, "55.00")
      assert_eventually_contains(view, "€160.00")
    end

    test "creates, edits, and deletes budget categories from the budget tab", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      view
      |> element("#budget-category-new-#{trip.id} button", "Add category")
      |> render_click()

      assert has_element?(view, "form[id^='budget-category-form-']")

      view
      |> form("form[id^='budget-category-form-']", %{
        budget_category: %{
          name: "Souvenirs",
          estimated_expense: %{price: %{amount: "75.00", currency: "EUR"}}
        }
      })
      |> render_submit()

      category =
        trip
        |> Planning.list_budget_categories()
        |> Enum.find(&(&1.name == "Souvenirs"))

      assert category.name == "Souvenirs"
      assert category.estimated_expense.price == Money.new(:EUR, "75.00")
      assert has_element?(view, "#budget-category-#{category.id}", "Souvenirs")
      assert_eventually_contains(view, "€75.00")

      view
      |> element("#budget-category-#{category.id} [phx-click='edit']")
      |> render_click()

      view
      |> form("#budget-category-form-budget-category-form-#{category.id}", %{
        budget_category: %{
          name: "Shopping",
          estimated_expense: %{price: %{amount: "90.00", currency: "EUR"}}
        }
      })
      |> render_submit()

      category = Planning.get_budget_category!(category.id)
      assert category.name == "Shopping"
      assert category.estimated_expense.price == Money.new(:EUR, "90.00")
      assert has_element?(view, "#budget-category-#{category.id}", "Shopping")
      assert_eventually_contains(view, "€90.00")

      view
      |> element("#budget-category-#{category.id} [phx-click='delete']")
      |> render_click()

      assert [food_category] = Planning.list_budget_categories(trip)
      assert food_category.name == "Food"
      refute has_element?(view, "#budget-category-#{category.id}")
    end

    test "edits the precreated food category and records actual expenses inline", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})
      category = Planning.get_food_budget_category!(trip)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      view
      |> element("#budget-category-#{category.id} [phx-click='edit']")
      |> render_click()

      assert has_element?(view, "label", "Price per day per person")
      assert has_element?(view, "label", "Days")
      assert has_element?(view, "label", "People")

      assert has_element?(
               view,
               "input[name='budget_category[food_setting][days_count]'][value='3']"
             )

      assert has_element?(
               view,
               "input[name='budget_category[food_setting][people_count]'][value='2']"
             )

      view
      |> form("#budget-category-form-budget-category-form-#{category.id}", %{
        budget_category: %{
          estimation_mode: "per_day",
          food_setting: %{
            price_per_day: %{amount: "10.00", currency: "EUR"},
            days_count: "3",
            people_count: "2"
          }
        }
      })
      |> render_submit()

      category = Planning.get_food_budget_category!(trip)

      assert category.estimated_expense.price == Money.new(:EUR, "60.00")
      assert category.food_setting.price_per_day == Money.new(:EUR, "10.00")
      assert_eventually_contains(view, "€60.00")

      view
      |> element("#budget-category-#{category.id} [phx-click='add_actual']")
      |> render_click()

      assert has_element?(view, "form[id^='budget-category-actual-new-form-#{category.id}-']")

      view
      |> form("form[id^='budget-category-actual-new-form-#{category.id}-']", %{
        expense: %{price: %{amount: "30.00", currency: "EUR"}}
      })
      |> render_submit()

      category = Planning.get_budget_category!(category.id)
      assert [actual_expense] = category.actual_expenses
      assert actual_expense.price == Money.new(:EUR, "30.00")
      assert category.estimated_expense.price == Money.new(:EUR, "60.00")
      assert_eventually_contains(view, "€30.00")
      assert has_element?(view, "form[id^='budget-category-actual-new-form-#{category.id}-']")

      view
      |> element("#budget-category-#{category.id} [phx-click='recalculate']")
      |> render_click()

      category = Planning.get_budget_category!(category.id)
      assert category.estimated_expense.price == Money.new(:EUR, "30.00")
      assert category.food_setting.price_per_day == Money.new(:EUR, "5.00")

      view
      |> element("#budget-category-actual-#{actual_expense.id} [phx-click='edit']")
      |> render_click()

      view
      |> form("#budget-category-actual-form-#{actual_expense.id}", %{
        expense: %{price: %{amount: "80.00", currency: "EUR"}}
      })
      |> render_submit()

      category = Planning.get_budget_category!(category.id)
      assert [updated_actual_expense] = category.actual_expenses
      assert updated_actual_expense.price == Money.new(:EUR, "80.00")
      assert category.estimated_expense.price == Money.new(:EUR, "80.00")
      assert_eventually_contains(view, "€80.00")

      view
      |> element("#budget-category-actual-#{actual_expense.id} [phx-click='edit']")
      |> render_click()

      view
      |> element("#budget-category-actual-#{actual_expense.id} [phx-click='delete']")
      |> render_click()

      assert Planning.get_budget_category!(category.id).actual_expenses == []
      refute has_element?(view, "#budget-category-actual-#{actual_expense.id}")

      view
      |> element("#budget-category-#{category.id} [phx-click='edit']")
      |> render_click()

      food_form = form(view, "#budget-category-form-budget-category-form-#{category.id}")

      render_change(food_form, %{
        budget_category: %{
          estimation_mode: "total"
        }
      })

      assert has_element?(view, "label", "Estimated cost")

      view
      |> form("#budget-category-form-budget-category-form-#{category.id}", %{
        budget_category: %{
          estimation_mode: "total",
          estimated_expense: %{price: %{amount: "120.00", currency: "EUR"}}
        }
      })
      |> render_submit()

      category = Planning.get_food_budget_category!(trip)
      assert category.estimated_expense.price == Money.new(:EUR, "120.00")
      assert category.food_setting.calculation_mode == "total"
    end

    test "adds actual expenses continuously from the bottom of their category", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})

      {:ok, category} =
        Planning.create_budget_category(trip, %{
          name: "Souvenirs",
          estimated_expense: %{price: Money.new(:EUR, "100.00")}
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      add_button =
        "#budget-category-#{category.id} button[phx-click='add_actual']"

      assert has_element?(view, add_button, "Add actual expense for Souvenirs")

      view
      |> element(add_button)
      |> render_click()

      actual_form = "form[id^='budget-category-actual-new-form-#{category.id}-']"
      assert has_element?(view, "#budget-category-actual-new-form-#{category.id}-0")

      assert has_element?(
               view,
               "#{actual_form}[phx-window-keydown='cancel_actual'][phx-key='escape']"
             )

      view
      |> form(actual_form, %{
        expense: %{price: %{amount: "0", currency: "EUR"}}
      })
      |> render_submit()

      assert has_element?(view, actual_form, "must be greater than 0")
      assert Planning.get_budget_category!(category.id).actual_expenses == []

      view
      |> form(actual_form, %{
        expense: %{price: %{amount: "25.00", currency: "EUR"}}
      })
      |> render_submit()

      assert has_element?(
               view,
               "#budget-category-actual-new-form-#{category.id}-1 input[name='expense[price][amount]'][value='0']"
             )

      view
      |> form(actual_form, %{
        expense: %{price: %{amount: "15.00", currency: "EUR"}}
      })
      |> render_submit()

      assert has_element?(view, "#budget-category-actual-new-form-#{category.id}-2")

      category = Planning.get_budget_category!(category.id)

      assert category.actual_expenses
             |> Enum.map(& &1.price)
             |> Enum.sort() == Enum.sort([Money.new(:EUR, "25.00"), Money.new(:EUR, "15.00")])

      view
      |> element(actual_form)
      |> render_keydown(%{"key" => "Escape"})

      refute has_element?(view, actual_form)

      html = render(view)
      {last_expense_position, _length} = :binary.match(html, "budget-category-actual-")
      {add_button_position, _length} = :binary.match(html, "Add actual expense for Souvenirs")

      assert last_expense_position < add_button_position
    end

    test "manually reconciles a zero-actual category after the trip is finished", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: Trip.finished(), currency: "EUR"})

      {:ok, category} =
        Planning.create_budget_category(trip, %{
          name: "Souvenirs",
          estimated_expense: %{price: Money.new(:EUR, "100.00")}
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      recalculate_button =
        "#budget-category-#{category.id} button[phx-click='recalculate']"

      assert has_element?(view, recalculate_button)

      view
      |> element(recalculate_button)
      |> render_click()

      category = Planning.get_budget_category!(category.id)
      assert category.estimated_expense.price == Money.new(:EUR, 0)
      assert_eventually_contains(view, "€0.00")
    end

    test "renders notes tab when selected", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      geonames_fixture()
      berlin = Geo.find_city_by_geonames_id("2950159")
      hamburg = Geo.find_city_by_geonames_id("2911298")

      {:ok, _day_destination} =
        Planning.create_destination(trip, %{city_id: berlin.id, start_day: 0, end_day: 0})

      {:ok, _outside_destination} =
        Planning.create_destination(trip, %{
          city_id: hamburg.id,
          start_day: trip.duration + 1,
          end_day: trip.duration + 1
        })

      {:ok, day_note} = Planning.create_note(trip, %{title: "Day note", day_index: 0})
      {:ok, unassigned_note} = Planning.create_note(trip, %{title: "Trip report", day_index: nil})

      # Act
      {:ok, view, html} = live(conn, ~p"/trips/#{trip.slug}?tab=notes")

      # Assert
      assert has_element?(view, "#notes-#{trip.id}")
      assert html =~ berlin.name
      assert html =~ hamburg.name
      assert html =~ day_note.title
      assert html =~ unassigned_note.title
      refute has_element?(view, "#notes-#{trip.id} a", "Add city")
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

    test "renders notes on notes tab and not activities tab", %{conn: conn} do
      # Arrange
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, day_note} = Planning.create_note(trip, %{title: "Day note", day_index: 0})
      {:ok, unassigned_note} = Planning.create_note(trip, %{title: "Trip report", day_index: nil})

      {:ok, outside_note} =
        Planning.create_note(trip, %{title: "Outside note", day_index: trip.duration + 1})

      # Act
      {:ok, _activities_view, activities_html} =
        live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      {:ok, _notes_view, notes_html} = live(conn, ~p"/trips/#{trip.slug}?tab=notes")

      # Assert
      refute activities_html =~ day_note.title
      refute activities_html =~ outside_note.title
      refute activities_html =~ unassigned_note.title

      assert notes_html =~ day_note.title
      assert notes_html =~ outside_note.title
      assert notes_html =~ unassigned_note.title
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
      assert Enum.any?(day_expenses, &(&1.id == outside_day_expense.id))
      assert Enum.any?(day_expenses, &(&1.id == inside_day_expense.id))

      notes = Planning.list_notes(trip)
      assert Enum.any?(notes, &(&1.id == outside_note.id))
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

    test "opens day reorder modal from the transfers table", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", duration: 3})

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      assert has_element?(view, "#open-reorder-days-0", "Move")

      view
      |> element("#open-reorder-days-0", "Move")
      |> render_click()

      assert has_element?(view, "#trip-reorder-days-modal")
      assert has_element?(view, "#move-day-up-0")
      assert has_element?(view, "#move-day-down-0")
    end

    test "reorders days from the modal and moves transfers", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", duration: 3})

      transfer_day0 =
        transfer_fixture(%{
          trip_id: trip.id,
          day_index: 0,
          vessel_number: "DAY0"
        })

      transfer_day1 =
        transfer_fixture(%{
          trip_id: trip.id,
          day_index: 1,
          vessel_number: "DAY1"
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}")

      view
      |> element("#open-reorder-days-0", "Move")
      |> render_click()

      view
      |> element("#move-day-down-0")
      |> render_click()

      assert Planning.get_transfer!(transfer_day0.id).day_index == 1
      assert Planning.get_transfer!(transfer_day1.id).day_index == 0
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

      activity =
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

      # Verify activity names stay prominent and priority is shown as an accent.
      assert has_element?(view, ".font-semibold", "Louvre Museum")
      assert has_element?(view, ".border-zinc-900", "Louvre Museum")
      assert has_element?(view, "[data-activity-drag-handle]", "1")
      assert has_element?(view, ".select-text", "Louvre Museum")

      assert has_element?(
               view,
               "[data-activity-toggle][aria-label='Toggle activity details'][aria-expanded='false']"
             )

      assert has_element?(view, "#activity-chevron-right-#{activity.id}")
      assert has_element?(view, "#activity-chevron-down-#{activity.id}.hidden")

      # Verify edit/delete buttons
      assert has_element?(view, "[phx-click='edit']")
      assert has_element?(view, "[phx-click='delete']")
    end

    test "renders medium and low priority activities distinctly", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      _medium_priority_activity =
        activity_fixture(%{
          trip_id: trip.id,
          name: "Medium priority activity",
          priority: 2,
          day_index: 0
        })

      _low_priority_activity =
        activity_fixture(%{
          trip_id: trip.id,
          name: "Low priority activity",
          priority: 1,
          day_index: 0
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      assert has_element?(view, ".border-zinc-400", "Medium priority activity")
      assert has_element?(view, ".border-zinc-200", "Low priority activity")
    end

    test "shows activity form when clicking add activity button", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})
      activity_fixture(%{trip_id: trip.id, day_index: 0, name: "Museum"})
      activity_fixture(%{trip_id: trip.id, day_index: 0, name: "Park"})

      # Act
      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      # Click the add activity button for day 0

      view
      |> element("#activity-new-0 [phx-click='add_activity']")
      |> render_click()

      # Assert

      assert has_element?(view, "form[id*='activity-form-new-activity-new-0']")
      assert has_element?(view, "p", "Add new activity")
      assert has_element?(view, "span", "3")
      assert has_element?(view, "label", "Activity Name")
      assert has_element?(view, "label", "Priority")
      assert has_element?(view, "label", "Price")
    end

    test "shows activity position when editing an activity", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      activity_fixture(%{trip_id: trip.id, day_index: 0, name: "Museum"})

      second_activity =
        activity_fixture(%{trip_id: trip.id, day_index: 0, name: "Park"})

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=activities")

      view
      |> element("[data-activity-id='#{second_activity.id}'] [phx-click='edit']")
      |> render_click()

      # Assert

      assert has_element?(view, "p", "Park")
      assert has_element?(view, "span", "2")
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
      assert has_element?(view, ".font-semibold", "Eiffel Tower")
      assert has_element?(view, ".border-zinc-900", "Eiffel Tower")

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

      {:ok, _activity} =
        Planning.create_activity(trip, %{
          name: "Anchor activity",
          day_index: 0,
          priority: 2,
          expense: %{price: Money.new(:EUR, 1), name: "Anchor activity", trip_id: trip.id}
        })

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      # Click the add expense button for day 0
      view
      |> element("#day-expense-new-0 [phx-click='add_day_expense']")
      |> render_click()

      # Assert

      assert has_element?(view, "form[id*='day-expense-form-new-day-expense-new-0']")
      assert has_element?(view, "label", "Name")
      assert has_element?(view, "label", "Price")
      assert has_element?(view, "label", "Link")
    end

    test "can create day expense via form", %{conn: conn} do
      # Arrange

      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, _activity} =
        Planning.create_activity(trip, %{
          name: "Anchor activity",
          day_index: 0,
          priority: 2,
          expense: %{price: Money.new(:EUR, 1), name: "Anchor activity", trip_id: trip.id}
        })

      # Act

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      # Open form
      view
      |> element("#day-expense-new-0 [phx-click='add_day_expense']")
      |> render_click()

      # Submit form
      view
      |> form("form[id*='day-expense-form-new-day-expense-new-0']", %{
        day_expense: %{
          name: "Metro card",
          link: "https://example.com/metro-card",
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
      assert day_expense.link == "https://example.com/metro-card"
      assert has_element?(view, "a[href='https://example.com/metro-card'][target='_blank']")
    end

    test "can delete day expense from budget tab", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

      {:ok, day_expense} =
        Planning.create_day_expense(trip, %{
          name: "Metro card",
          day_index: 0,
          expense: %{price: Money.new(:EUR, 12), name: "Metro card", trip_id: trip.id}
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      view
      |> element("[data-day-expense-id='#{day_expense.id}'] [phx-click='delete']")
      |> render_click()

      day_expenses = Planning.list_day_expenses(trip)
      refute Enum.any?(day_expenses, &(&1.id == day_expense.id))
    end

    test "recalculates budget when the food category changes", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: "0_draft", currency: "EUR"})
      food_category = Planning.get_food_budget_category!(trip)

      {:ok, _expense} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 40), name: "Souvenirs"})

      trip = Planning.get_trip!(trip.id)

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

      assert render(view) =~ "€40.00"

      {:ok, updated_food_category} =
        Planning.update_budget_category(food_category, %{
          food_setting: %{
            price_per_day: Money.new(:EUR, 10),
            days_count: 2,
            people_count: 3,
            calculation_mode: "per_day"
          }
        })

      assert updated_food_category.estimated_expense.price == Money.new(:EUR, 60)

      assert has_element?(view, "#budget-category-#{food_category.id}", "Food")
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

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}?tab=budget")

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
      assert has_element?(view, "#activities-#{trip.id}[data-can-edit='true']")
      assert has_element?(view, ".draggable-activity")

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
