defmodule HamsterTravelWeb.UserAuth do
  @moduledoc """
  Helpers for the user authentication
  """

  import HamsterTravelWeb.Gettext
  import Plug.Conn
  import Phoenix.Controller

  alias HamsterTravel.Accounts
  alias HamsterTravelWeb.Router.Helpers, as: Routes
  alias Phoenix.Component
  alias Phoenix.LiveView

  def on_mount(:set_current_user, _params, session, socket) do
    case session do
      %{"user_token" => user_token} ->
        user = Accounts.get_user_by_session_token(user_token)
        set_locale(user.locale)
        {:cont, Component.assign_new(socket, :current_user, fn -> user end)}

      %{} ->
        set_locale("en")
        {:cont, Component.assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session do
      %{"user_token" => user_token} ->
        user = Accounts.get_user_by_session_token(user_token)

        set_locale(user.locale)
        {:cont, Component.assign_new(socket, :current_user, fn -> user end)}

      %{} ->
        set_locale("en")
        {:halt, redirect_require_login(socket)}
    end
  end

  defp set_locale(locale) do
    Gettext.put_locale(HamsterTravelWeb.Gettext, locale)
    {:ok, _} = Cldr.put_locale(HamsterTravelWeb.Cldr, locale)
  end

  defp redirect_require_login(socket) do
    socket
    |> LiveView.put_flash(:error, gettext("Please sign in"))
    |> LiveView.redirect(to: Routes.user_session_path(socket, :new))
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      HamsterTravelWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the user by looking into the session
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)

    if user do
      set_locale(user.locale)
    else
      set_locale("en")
    end

    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      {nil, conn}
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.user_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end
