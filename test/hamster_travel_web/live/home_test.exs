defmodule HamsterTravelWeb.HomeTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  describe "Home page" do
    test "renders home page for authenticated user", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create some trips for the user to ensure there's data to display
      trip_fixture(%{author_id: user.id, status: "1_planned"})
      trip_fixture(%{author_id: user.id, status: "2_finished"})

      # Visit the home page
      {:ok, view, html} = live(conn, ~p"/")

      # Assert the page renders successfully
      assert html =~ "Home"

      # Verify the page contains expected elements for an authenticated user
      assert has_element?(view, "h2", "Next travels")
      assert has_element?(view, "h2", "Last travels")

      # Verify that the trips are displayed
      assert has_element?(view, "div.grid.grid-cols-1")
    end

    test "renders landing page for unauthenticated user", %{conn: conn} do
      # Visit the home page without logging in
      {:ok, view, html} = live(conn, ~p"/")

      # Assert the page renders successfully
      assert html =~ "Home"

      # Verify the page contains expected elements for an unauthenticated user
      assert html =~ "Welcome to hamster travel!"
      assert has_element?(view, "a", "login")

      # Verify that no trips are displayed
      refute html =~ "Next travels"
      refute html =~ "Last travels"
    end
  end
end
