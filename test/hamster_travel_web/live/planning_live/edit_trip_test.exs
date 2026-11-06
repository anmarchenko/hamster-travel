defmodule HamsterTravelWeb.Planning.EditTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.GeoFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip

  describe "Edit trip page" do
    test "orders currencies by home, destination, and major currencies while preserving the selection",
         %{conn: conn} do
      user = user_fixture(%{default_currency: "GBP"})
      trip = trip_fixture(user, %{currency: "CHF"})
      geonames_fixture()
      country = country_fixture(%{iso: "TH"})
      region = region_fixture(country)
      city = city_fixture(country, region)

      {:ok, _destination} =
        Planning.create_destination(trip, %{city_id: city.id, start_day: 0, end_day: 2})

      {:ok, _view, html} = live(log_in_user(conn, user), ~p"/trips/#{trip.slug}/edit")

      options =
        html
        |> Floki.parse_document!()
        |> Floki.find("select[name='trip[currency]'] option")

      assert Enum.take(Floki.attribute(options, "value"), 5) == [
               "GBP",
               "THB",
               "EUR",
               "USD",
               "CHF"
             ]

      assert Floki.attribute(Floki.find(options, "[selected]"), "value") == ["CHF"]
    end

    test "rebuilds an edit form from the recovery change payload", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip =
        trip_fixture(user, %{
          status: Trip.planned(),
          dates_unknown: true,
          duration: 4,
          start_date: nil,
          end_date: nil
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}/edit")

      view
      |> element("#trip-form")
      |> render_change(%{
        "_target" => ["trip", "name"],
        "trip" => %{
          "name" => "Recovered edit",
          "status" => Trip.planned(),
          "currency" => trip.currency,
          "dates_unknown" => "false",
          "start_date" => "2026-08-10",
          "end_date" => "2026-08-15",
          "people_count" => "3",
          "private" => "false"
        }
      })

      assert has_element?(view, "#trip-form input[name='trip[name]'][value='Recovered edit']")
      assert has_element?(view, "#trip-form input[name='trip[start_date]'][value='2026-08-10']")
      assert has_element?(view, "#trip-form input[name='trip[end_date]'][value='2026-08-15']")
      refute has_element?(view, "#trip-form input[name='trip[duration]']")
    end

    test "keeps return_to in cancel and save flows", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      trip = trip_fixture(%{author_id: user.id, status: Trip.planned()})
      return_to = "/plans?page=2&q=Searchable"

      {:ok, view, html} =
        live(conn, "/trips/#{trip.slug}/edit?return_to=#{URI.encode_www_form(return_to)}")

      assert html =~ ~s(href="/trips/#{trip.slug}?return_to=%2Fplans%3Fpage%3D2%26q%3DSearchable")

      view
      |> form("form#trip-form",
        trip: %{
          name: "Edited trip",
          status: Trip.planned(),
          currency: trip.currency,
          dates_unknown: "false",
          start_date: to_string(trip.start_date),
          end_date: to_string(trip.end_date),
          people_count: Integer.to_string(trip.people_count),
          private: to_string(trip.private)
        }
      )
      |> render_submit()

      assert_redirect(view, "/trips/edited-trip?return_to=%2Fplans%3Fpage%3D2%26q%3DSearchable")
    end

    test "shows date validation errors when finishing trip with unknown dates", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      trip =
        trip_fixture(user, %{
          status: Trip.planned(),
          dates_unknown: true,
          duration: 4,
          start_date: nil,
          end_date: nil
        })

      {:ok, view, _html} = live(conn, ~p"/trips/#{trip.slug}/edit")

      view
      |> form("form#trip-form", trip: %{status: Trip.finished()})
      |> render_change()

      html =
        view
        |> form("form#trip-form")
        |> render_submit()

      assert html =~ "can&#39;t be blank"

      persisted_trip = Planning.get_trip!(trip.id)
      assert persisted_trip.status == Trip.planned()
      assert persisted_trip.dates_unknown
      assert persisted_trip.start_date == nil
      assert persisted_trip.end_date == nil
    end
  end
end
