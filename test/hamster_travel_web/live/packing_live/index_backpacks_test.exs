defmodule HamsterTravelWeb.Packing.IndexBackpacksTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PackingFixtures

  describe "Index backpacks page" do
    test "renders backpacks page for authenticated user with backpacks", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create some backpacks for the user
      backpack1 = backpack_fixture(%{user_id: user.id, name: "Summer Trip"})
      backpack2 = backpack_fixture(%{user_id: user.id, name: "Winter Vacation"})

      # Visit the backpacks page
      {:ok, view, html} = live(conn, ~p"/backpacks")

      # Assert the page renders successfully
      assert html =~ "Backpacks"

      # Verify that the backpacks grid is displayed
      assert has_element?(view, "div.grid.grid-cols-1")

      # Check for the "New backpack" button
      assert has_element?(view, "a", "New backpack")

      # Verify that the created backpacks are displayed
      assert html =~ backpack1.name
      assert html =~ backpack2.name

      # Verify the backpack details are displayed
      assert html =~ "#{backpack1.days} day"
      assert html =~ "#{backpack1.nights} night"
    end

    test "renders backpacks page with no backpacks", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the backpacks page without creating any backpacks
      {:ok, _view, html} = live(conn, ~p"/backpacks")

      # Assert the page renders successfully
      assert html =~ "Backpacks"

      # Check for the "New backpack" button
      assert html =~ "New backpack"
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      # Try to visit the backpacks page without logging in
      result = live(conn, ~p"/backpacks")

      # Assert that we are redirected to the login page
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = result
    end
  end
end
