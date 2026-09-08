defmodule HamsterTravelWeb.LocaleSwitcherTest do
  use HamsterTravelWeb.ConnCase, async: true

  import HamsterTravel.AccountsFixtures
  import Phoenix.LiveViewTest

  alias HamsterTravel.Accounts

  test "is hidden on the login page", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/users/log_in")

    refute has_element?(view, "[data-locale-switch]")
  end

  test "updates the user's locale and reloads the current path", %{conn: conn} do
    user = user_fixture(%{locale: "en"})
    conn = log_in_user(conn, user)
    path = ~p"/plans?q=family"
    {:ok, view, _html} = live(conn, path)

    view
    |> element("[data-locale-switch]")
    |> render_click()

    assert_redirect(view, path)
    assert Accounts.get_user!(user.id).locale == "ru"
  end
end
