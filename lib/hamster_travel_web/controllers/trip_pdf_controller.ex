defmodule HamsterTravelWeb.TripPdfController do
  use HamsterTravelWeb, :controller

  use Gettext, backend: HamsterTravelWeb.Gettext

  require Logger

  alias HamsterTravel.Planning
  alias HamsterTravelWeb.TripPdf

  def show(conn, %{"trip_slug" => trip_slug}) do
    set_locale(conn.assigns.current_user.locale || "en")
    trip = Planning.fetch_trip!(trip_slug, conn.assigns.current_user)
    display_currency = conn.assigns.current_user.default_currency || trip.currency
    filename = build_pdf_filename(trip.slug)

    case TripPdf.render(trip, display_currency) do
      {:ok, pdf_binary} ->
        conn
        |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate, max-age=0")
        |> put_resp_header("pragma", "no-cache")
        |> put_resp_header("expires", "0")
        |> send_download({:binary, pdf_binary},
          filename: filename,
          content_type: "application/pdf"
        )

      {:error, reason} ->
        Logger.error("Trip PDF export failed for trip=#{trip.id}: #{inspect(reason)}")

        conn
        |> put_flash(:error, gettext("Failed to export trip to PDF."))
        |> redirect(to: ~p"/trips/#{trip.slug}")
    end
  end

  defp set_locale(locale) do
    Gettext.put_locale(HamsterTravelWeb.Gettext, locale)
    {:ok, _} = Cldr.put_locale(HamsterTravelWeb.Cldr, locale)
    :ok
  end

  defp build_pdf_filename(trip_slug) do
    timestamp =
      DateTime.utc_now()
      |> Calendar.strftime("%Y%m%d-%H%M%S")

    "#{trip_slug}-plan-#{timestamp}.pdf"
  end
end
