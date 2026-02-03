defmodule HamsterTravelWeb.Accounts.ProfileLiveTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures
  import HamsterTravel.GeoFixtures

  alias HamsterTravel.Geo
  alias HamsterTravel.Planning
  alias HamsterTravel.Planning.Trip

  describe "Profile page" do
    test "renders profile stats and visited countries", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      geonames_fixture()
      berlin = Geo.find_city_by_geonames_id("2950159")
      france = country_fixture()
      region = region_fixture(france)
      paris = city_fixture(france, region)

      finished_trip_de = trip_fixture(user, %{status: Trip.finished()})

      {:ok, _} =
        Planning.create_destination(finished_trip_de, %{
          city_id: berlin.id,
          start_day: 0,
          end_day: 1
        })

      finished_trip_fr = trip_fixture(user, %{status: Trip.finished()})

      {:ok, _} =
        Planning.create_destination(finished_trip_fr, %{
          city_id: paris.id,
          start_day: 0,
          end_day: 1
        })

      planned_trip = trip_fixture(user, %{status: Trip.planned()})

      {:ok, _} =
        Planning.create_destination(planned_trip, %{city_id: paris.id, start_day: 0, end_day: 1})

      expected_days = finished_trip_de.duration + finished_trip_fr.duration

      {:ok, _view, html} = live(conn, ~p"/profile")

      assert html =~ user.name
      assert html =~ "Visited countries"
      assert html =~ france.name
      assert html =~ berlin.country.name
      stats = stats_map(html)

      assert stats["Total trips"] == "2"
      assert stats["Countries"] == "2"
      assert stats["Days on the road"] == Integer.to_string(expected_days)
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/profile")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "Please sign in"} = flash
    end
  end

  defp stats_map(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("div.flex.items-center.gap-4.rounded-2xl")
    |> Enum.reduce(%{}, fn stat, acc ->
      label =
        stat
        |> Floki.find("p.text-xs")
        |> Floki.text()
        |> String.trim()

      value =
        stat
        |> Floki.find("p.text-xl")
        |> Floki.text()
        |> String.trim()

      Map.put(acc, label, value)
    end)
  end
end
