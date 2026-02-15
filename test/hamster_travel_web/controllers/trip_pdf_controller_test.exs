defmodule HamsterTravelWeb.TripPdfControllerTest do
  use HamsterTravelWeb.ConnCase

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.PlanningFixtures

  defmodule MockRenderer do
    def render(_html, _opts), do: {:ok, "%PDF-1.4 test pdf"}
  end

  setup do
    original = Application.get_env(:hamster_travel, :trip_pdf_renderer)
    Application.put_env(:hamster_travel, :trip_pdf_renderer, MockRenderer)

    on_exit(fn ->
      Application.put_env(:hamster_travel, :trip_pdf_renderer, original)
    end)

    :ok
  end

  test "downloads trip PDF", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    trip = trip_fixture(%{author_id: user.id, status: "0_draft"})

    conn = get(conn, ~p"/trips/#{trip.slug}/export.pdf")

    assert conn.status == 200
    assert [content_type | _] = get_resp_header(conn, "content-type")
    assert String.starts_with?(content_type, "application/pdf")
    assert Enum.any?(get_resp_header(conn, "cache-control"), &String.contains?(&1, "no-store"))

    assert Enum.any?(get_resp_header(conn, "content-disposition"), fn disposition ->
             String.contains?(disposition, "attachment") &&
               String.contains?(disposition, "#{trip.slug}-plan-") &&
               String.contains?(disposition, ".pdf")
           end)

    assert conn.resp_body =~ "%PDF-1.4"
  end
end
