defmodule HamsterTravelWeb.HealthControllerTest do
  use HamsterTravelWeb.ConnCase, async: true

  test "reports that the application is up without authentication", %{conn: conn} do
    conn = get(conn, ~p"/up")

    assert json_response(conn, 200) == %{"status" => "ok"}
  end
end
