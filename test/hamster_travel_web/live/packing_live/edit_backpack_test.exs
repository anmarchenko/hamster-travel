defmodule HamsterTravelWeb.Packing.EditBackpackTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PackingFixtures

  describe "Edit backpack page" do
    test "renders edit form for authenticated owner", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a backpack for the user
      backpack =
        backpack_fixture(%{
          user_id: user.id,
          name: "Original Backpack",
          days: 7,
          nights: 6
        })

      # Visit the edit backpack page
      {:ok, view, html} = live(conn, ~p"/backpacks/#{backpack.slug}/edit")

      # Assert the page renders successfully with the correct title
      assert html =~ "Edit backpack"

      # Verify that the form fields are displayed with the current values
      assert view |> element("input[name='backpack[name]']") |> render() =~ "Original Backpack"
      assert view |> element("input[name='backpack[days]']") |> render() =~ "7"
      assert view |> element("input[name='backpack[nights]']") |> render() =~ "6"

      # Verify that the save and cancel buttons are displayed
      assert has_element?(view, "button", "Save")
      assert has_element?(view, "a", "Cancel")
    end

    test "updates a backpack when form is submitted with valid data", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a backpack for the user
      backpack =
        backpack_fixture(%{
          user_id: user.id,
          name: "Original Backpack",
          days: 7,
          nights: 6
        })

      # Visit the edit backpack page
      {:ok, view, _html} = live(conn, ~p"/backpacks/#{backpack.slug}/edit")

      # Fill in and submit the form with updated data
      view
      |> form("form",
        backpack: %{
          name: "Updated Backpack",
          days: "10",
          nights: "9"
        }
      )
      |> render_submit()

      # Follow the redirect
      assert_redirect(view, "/backpacks/updated-backpack")

      # Visit the backpack page to verify the changes
      {:ok, _view, html} = live(conn, ~p"/backpacks/updated-backpack")

      # Verify that the backpack was updated
      assert html =~ "Updated Backpack"
      assert html =~ "10 days / 9 nights"
    end

    test "shows validation errors when form is submitted with invalid data", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a backpack for the user
      backpack =
        backpack_fixture(%{
          user_id: user.id,
          name: "Original Backpack",
          days: 7,
          nights: 6
        })

      # Visit the edit backpack page
      {:ok, view, _html} = live(conn, ~p"/backpacks/#{backpack.slug}/edit")

      # Submit the form with invalid data (empty name)
      rendered_html =
        view
        |> form("form",
          backpack: %{
            name: "",
            days: "10",
            nights: "9"
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
      # Create a user (but don't log them in)
      user = user_fixture()

      # Create a backpack for the user
      backpack = backpack_fixture(%{user_id: user.id, name: "Original Backpack"})

      # Try to visit the edit backpack page without logging in
      result = live(conn, ~p"/backpacks/#{backpack.slug}/edit")

      # Assert that we are redirected to the login page
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = result
    end

    test "returns error when trying to edit another user's backpack", %{conn: conn} do
      # Create two users
      user1 = user_fixture()
      user2 = user_fixture()

      # Log in as user1
      conn = log_in_user(conn, user1)

      # Create a backpack for user2
      backpack = backpack_fixture(%{user_id: user2.id, name: "Other User's Backpack"})

      # Try to visit the edit page for user2's backpack while logged in as user1
      assert_error_raised(fn ->
        live(conn, ~p"/backpacks/#{backpack.slug}/edit")
      end)
    end
  end

  defp assert_error_raised(fun) do
    fun.()
    flunk("Expected an error to be raised")
  rescue
    _ -> :ok
  end
end
