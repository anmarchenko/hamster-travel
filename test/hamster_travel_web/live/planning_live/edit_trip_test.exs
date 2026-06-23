defmodule HamsterTravelWeb.Planning.EditTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip

  describe "Edit trip page" do
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
