defmodule HamsterTravelWeb.LocaleControllerTest do
  use HamsterTravelWeb.ConnCase, async: true

  import HamsterTravel.AccountsFixtures

  alias HamsterTravel.Accounts

  describe "POST /users/locale" do
    test "stores an anonymous visitor's locale in the session", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "http://www.example.com/users/log_in?from=locale")
        |> post(~p"/users/locale", %{"locale" => "ru"})

      assert get_session(conn, :preferred_locale) == "ru"
      assert redirected_to(conn) == "/users/log_in?from=locale"

      response = conn |> recycle() |> get(~p"/users/log_in") |> html_response(200)

      assert response =~ ~s(<html lang="ru")
      assert response =~ ~s(data-current-locale="ru")
    end

    test "persists an authenticated user's locale", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/users/locale", %{"locale" => "ru"})

      assert get_session(conn, :preferred_locale) == "ru"
      assert Accounts.get_user!(user.id).locale == "ru"
      assert redirected_to(conn) == "/"

      response = conn |> recycle() |> get(~p"/") |> html_response(200)

      assert response =~ ~s(<html lang="ru")
      assert response =~ ~s(data-current-locale="ru")
    end

    test "rejects unsupported locales", %{conn: conn} do
      conn = post(conn, ~p"/users/locale", %{"locale" => "de"})

      assert response(conn, 422) == ""
      refute get_session(conn, :preferred_locale)
    end

    test "does not redirect to an external referrer", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "https://example.org/surprise")
        |> post(~p"/users/locale", %{"locale" => "ru"})

      assert redirected_to(conn) == "/"
    end
  end
end
