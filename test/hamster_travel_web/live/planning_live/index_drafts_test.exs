defmodule HamsterTravelWeb.Planning.IndexDraftsTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  alias HamsterTravel.Planning.Trip

  describe "Index drafts page" do
    test "renders drafts page for authenticated user with drafts", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create some draft trips for the user
      trip_fixture(%{author_id: user.id, status: Trip.draft()})
      trip_fixture(%{author_id: user.id, status: Trip.draft()})

      # Visit the drafts page
      {:ok, view, html} = live(conn, ~p"/drafts")

      # Assert the page renders successfully
      assert html =~ "Drafts"

      # Verify that the drafts are displayed
      assert has_element?(view, "div.grid.grid-cols-1")

      # Verify that we have at least one trip card
      assert has_element?(view, ".flex.flex-row")

      # Check for the "Create draft" button
      assert has_element?(view, "a", "Create draft")
    end

    test "renders drafts page with no drafts", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the drafts page without creating any drafts
      {:ok, _view, html} = live(conn, ~p"/drafts")

      # Assert the page renders successfully
      assert html =~ "Drafts"

      # Check for the "Create draft" button
      assert html =~ "Create draft"
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      # Try to visit the drafts page without logging in
      result = live(conn, ~p"/drafts")

      # Assert that we are redirected to the login page
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = result
    end
  end
end
