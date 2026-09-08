defmodule HamsterTravelWeb.LocaleController do
  use HamsterTravelWeb, :controller

  alias HamsterTravel.Accounts

  @supported_locales ~w(en ru)

  def update(conn, %{"locale" => locale}) when locale in @supported_locales do
    case persist_locale(conn.assigns[:current_user], locale) do
      :ok ->
        conn
        |> put_session(:preferred_locale, locale)
        |> redirect(to: return_path(conn))

      {:error, _changeset} ->
        send_resp(conn, :unprocessable_entity, "")
    end
  end

  def update(conn, _params) do
    send_resp(conn, :unprocessable_entity, "")
  end

  defp persist_locale(nil, _locale), do: :ok

  defp persist_locale(user, locale) do
    case Accounts.update_user_locale(user, locale) do
      {:ok, _user} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp return_path(conn) do
    with [referrer] <- get_req_header(conn, "referer"),
         %URI{host: host, path: path} = uri <- URI.parse(referrer),
         true <- host == conn.host,
         true <- is_binary(path) and String.starts_with?(path, "/"),
         false <- String.starts_with?(path, "//") do
      if uri.query, do: path <> "?" <> uri.query, else: path
    else
      _ -> ~p"/"
    end
  end
end
