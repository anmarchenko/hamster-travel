defmodule HamsterTravelWeb.UserLoginLiveTest do
  use HamsterTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import HamsterTravel.AccountsFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Log in"
      assert html =~ "Forgot your password?"
      assert has_element?(lv, "#login-form[phx-change='form_changed']")
      assert has_element?(lv, "input[name='user[email]'][class*='dark:text-gray-200']")
      assert has_element?(lv, "input[name='user[password]'][class*='dark:text-gray-200']")
    end

    test "accepts the complete recovery change payload", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      html =
        lv
        |> element("#login-form")
        |> render_change(%{
          "_target" => ["user", "email"],
          "user" => %{"email" => "recover@example.com", "password" => "unsaved-password"}
        })

      assert html =~ ~s(id="login-form")
      assert html =~ ~s(phx-change="form_changed")
      assert html =~ "recover@example.com"
      assert html =~ "unsaved-password"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/log_in")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login-form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login-form",
          user: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/users/log_in"
    end
  end

  # describe "login navigation" do
  #   test "redirects to forgot password page when the Forgot Password button is clicked", %{
  #     conn: conn
  #   } do
  #     {:ok, lv, _html} = live(conn, ~p"/users/log_in")

  #     {:ok, conn} =
  #       lv
  #       |> element(~s|main a:fl-contains("Forgot your password?")|)
  #       |> render_click()
  #       |> follow_redirect(conn, ~p"/users/reset_password")

  #     assert conn.resp_body =~ "Forgot your password?"
  #   end
  # end
end
