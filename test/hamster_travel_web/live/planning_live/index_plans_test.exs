defmodule HamsterTravelWeb.Planning.IndexPlansTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning

  describe "Index plans page" do
    test "renders plans page for authenticated user", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create some trips for the user to ensure there's data to display
      trip_fixture(%{author_id: user.id, status: "1_planned"})
      trip_fixture(%{author_id: user.id, status: "1_planned"})

      # Visit the plans page
      {:ok, view, html} = live(conn, ~p"/plans")

      # Assert the page renders successfully
      assert html =~ "Travels"

      # Verify that the plans are displayed
      assert has_element?(view, "div.grid.grid-cols-1")

      # Verify that we have at least one trip card
      assert has_element?(view, ".flex.flex-row")

      # Check for the "Planned" status badge
      assert has_element?(view, "span", "Planned")

      # Check for the Create trip button
      assert has_element?(view, "a", "Create trip")
    end

    test "renders plans page with no plans", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the plans page without creating any plans
      {:ok, _view, html} = live(conn, ~p"/plans")

      # Assert the page renders successfully
      assert html =~ "Travels"

      # Check for the Create trip button
      assert html =~ "Create trip"
    end

    test "uses current user default currency for displayed budget", %{conn: conn} do
      user = user_fixture(%{default_currency: "USD"})
      conn = log_in_user(conn, user)

      trip = trip_fixture(%{author_id: user.id, status: "1_planned", currency: "EUR"})

      {:ok, _expense} =
        Planning.create_expense(trip, %{price: Money.new(:EUR, 100), name: "Budget item"})

      {:ok, _view, html} = live(conn, ~p"/plans")

      assert html =~ "$110.00"
      assert html =~ "€100.00"
    end
  end
end
