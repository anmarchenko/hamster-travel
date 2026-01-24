defmodule HamsterTravelWeb.Planning.CreateTripTest do
  use HamsterTravelWeb.ConnCase

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.GeoFixtures

  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip
  alias HamsterTravel.Repo

  describe "Create trip page" do
    test "creates a trip from a copy", %{conn: conn} do
      user = user_fixture() |> Repo.preload(:friendships)
      conn = log_in_user(conn, user)

      {:ok, trip} =
        Planning.create_trip(
          %{
            name: "Original trip",
            dates_unknown: false,
            start_date: ~D[2024-02-01],
            end_date: ~D[2024-02-03],
            currency: "EUR",
            status: Trip.planned(),
            private: false,
            people_count: 2
          },
          user
        )

      geonames_fixture()
      city = HamsterTravel.Geo.find_city_by_geonames_id("2950159")
      {:ok, destination} = Planning.create_destination(trip, %{city_id: city.id, start_day: 0, end_day: 1})

      {:ok, view, html} = live(conn, ~p"/trips/new?copy=#{trip.id}")

      assert html =~ "Create a new trip"

      assert view |> element("input[name='trip[name]']") |> render() =~
               "Original trip (Copy)"

      assert view |> element("input[name='trip[start_date]']") |> render() =~
               "2024-02-01"

      assert view |> element("input[name='trip[end_date]']") |> render() =~
               "2024-02-03"

      view
      |> form("form#trip-form",
        trip: %{
          name: "Copied trip",
          status: Trip.planned(),
          currency: "EUR",
          dates_unknown: "false",
          start_date: "2024-02-01",
          end_date: "2024-02-03",
          people_count: "2",
          private: "false"
        }
      )
      |> render_submit()

      assert_redirect(view, "/trips/copied-trip")

      copied_trip = Planning.fetch_trip!("copied-trip", user)

      assert copied_trip.name == "Copied trip"
      assert copied_trip.author_id == user.id

      assert [copied_destination] = copied_trip.destinations
      assert copied_destination.city_id == destination.city_id
      assert copied_destination.start_day == destination.start_day
      assert copied_destination.end_day == destination.end_day
      refute copied_destination.id == destination.id
    end
  end
end
