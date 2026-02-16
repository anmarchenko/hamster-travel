defmodule HamsterTravelWeb.Planning.EditTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip

  describe "Edit trip page" do
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
