defmodule HamsterTravelWeb.Packing.CreateBackpackTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PackingFixtures

  describe "Create backpack page" do
    test "renders backpack form for authenticated user", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the create backpack page
      {:ok, view, html} = live(conn, ~p"/backpacks/new")

      # Assert the page renders successfully with the correct title
      assert html =~ "New backpack"

      # Verify that the form fields are displayed
      assert has_element?(view, "input[name='backpack[name]']")
      assert has_element?(view, "input[name='backpack[days]']")
      assert has_element?(view, "input[name='backpack[nights]']")
      assert has_element?(view, "select[name='backpack[template]']")

      # Verify that the save and cancel buttons are displayed
      assert has_element?(view, "button", "Save")
      assert has_element?(view, "a", "Cancel")
    end

    test "creates a new backpack when form is submitted with valid data", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the create backpack page
      {:ok, view, _html} = live(conn, ~p"/backpacks/new")

      # Fill in and submit the form
      view
      |> form("form",
        backpack: %{
          name: "Test Backpack",
          days: "5",
          nights: "4",
          template: "default"
        }
      )
      |> render_submit()

      # Follow the redirect
      assert_redirect(view, "/backpacks/test-backpack")

      # Navigate to the backpacks page to verify the backpack was created
      {:ok, _view, html} = live(conn, ~p"/backpacks")

      # Verify that the new backpack is displayed
      assert html =~ "Test Backpack"
    end

    test "shows validation errors when form is submitted with invalid data", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Visit the create backpack page
      {:ok, view, _html} = live(conn, ~p"/backpacks/new")

      # Submit the form with invalid data (empty name)
      rendered_html =
        view
        |> form("form",
          backpack: %{
            name: "",
            days: "5",
            nights: "4",
            template: "default"
          }
        )
        |> render_submit()

      # Verify that validation errors are displayed
      assert rendered_html =~ "can&#39;t be blank"

      # Verify we're still on the form page
      assert rendered_html =~ "Name"
      assert rendered_html =~ "Days"
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      # Try to visit the create backpack page without logging in
      result = live(conn, ~p"/backpacks/new")

      # Assert that we are redirected to the login page
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = result
    end

    test "creates a backpack from a template when copying", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create an existing backpack to copy from
      existing_backpack =
        backpack_fixture(%{
          user_id: user.id,
          name: "Original Backpack",
          days: 7,
          nights: 6
        })

      # Visit the create backpack page with copy parameter
      {:ok, view, html} = live(conn, ~p"/backpacks/new?copy=#{existing_backpack.id}")

      # Assert the page renders with the copy info
      assert html =~ "New backpack"

      # Verify that the form is pre-filled with the original backpack's data
      assert view |> element("input[name='backpack[name]']") |> render() =~
               "Original Backpack (Copy)"

      assert view |> element("input[name='backpack[days]']") |> render() =~ "7"
      assert view |> element("input[name='backpack[nights]']") |> render() =~ "6"

      # Verify that the template selector is not shown when copying
      refute has_element?(view, "select[name='backpack[template]']")

      # Submit the form with the pre-filled data
      view
      |> form("form",
        backpack: %{
          name: "Copied Backpack",
          days: "7",
          nights: "6"
        }
      )
      |> render_submit()

      # Follow the redirect
      assert_redirect(view, "/backpacks/copied-backpack")

      # Navigate to the backpacks page to verify the backpack was created
      {:ok, _view, html} = live(conn, ~p"/backpacks")

      # Verify that the new backpack is displayed
      assert html =~ "Copied Backpack"
    end
  end
end
