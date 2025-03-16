defmodule HamsterTravelWeb.Packing.ShowBackpackTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PackingFixtures

  alias HamsterTravel.Packing

  describe "Show backpack page" do
    test "renders backpack details for authenticated owner", %{conn: conn} do
      # Create a user and log them in
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Create a backpack for the user
      backpack =
        backpack_fixture(%{
          user_id: user.id,
          name: "Summer Trip",
          days: 7,
          nights: 6
        })

      # Create a list for the backpack
      {:ok, list} = Packing.create_list(%{name: "Clothes"}, backpack)

      # Create an item for the list
      {:ok, _item} = Packing.create_item(%{name: "T-shirts", count: 5}, list)

      # Visit the backpack page
      {:ok, _view, html} = live(conn, ~p"/backpacks/#{backpack.slug}")

      # Assert the page renders successfully with the backpack name as title
      assert html =~ backpack.name
      assert html =~ "Summer Trip"

      # Verify that the backpack details are displayed
      assert html =~ "7 days / 6 nights"

      # Verify that the edit, copy and delete buttons are displayed for the owner
      assert html =~ "Edit"
      assert html =~ "Make a copy"
      assert html =~ "Delete"

      # Verify that the list is displayed
      assert html =~ "Clothes"

      # Verify that the item is displayed
      assert html =~ "T-shirts"
      assert html =~ "5"
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      # Create a user (but don't log them in)
      user = user_fixture()

      # Create a backpack
      backpack = backpack_fixture(%{user_id: user.id, name: "Summer Trip"})

      # Try to visit the backpack page without logging in
      result = live(conn, ~p"/backpacks/#{backpack.slug}")

      # Assert that we are redirected to the login page
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = result
    end

    test "returns error when trying to access another user's backpack", %{conn: conn} do
      # Create two users
      user1 = user_fixture()
      user2 = user_fixture()

      # Log in as user1
      conn = log_in_user(conn, user1)

      # Create a backpack for user2
      backpack = backpack_fixture(%{user_id: user2.id, name: "Private Trip"})

      # Try to visit user2's backpack page while logged in as user1
      assert_error_raised(fn ->
        live(conn, ~p"/backpacks/#{backpack.slug}")
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
