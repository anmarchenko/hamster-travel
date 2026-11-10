defmodule HamsterTravelWeb.UserSessionController do
  use HamsterTravelWeb, :controller

  alias HamsterTravel.Accounts
  alias HamsterTravelWeb.UserAuth

  use Gettext, backend: HamsterTravelWeb.Gettext

  def create(conn, %{"_action" => "password_updated", "user" => user_params}) do
    conn
    |> put_session(:user_return_to, ~p"/profile")
    |> log_in(user_params)
  end

  def create(conn, %{"user" => user_params}) do
    log_in(conn, user_params)
  end

  defp log_in(conn, %{"email" => email, "password" => password} = user_params) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("Invalid email or password"))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    UserAuth.log_out_user(conn)
  end
end
