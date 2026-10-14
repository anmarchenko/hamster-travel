defmodule HamsterTravelWeb.HealthControllerTest do
  use HamsterTravelWeb.ConnCase, async: true

  alias HamsterTravel.Repo

  test "reports that the application and database are up without authentication", %{conn: conn} do
    conn = get(conn, ~p"/up")

    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "reports service unavailable when the database query fails", %{conn: conn} do
    Repo.transaction(fn ->
      # A failed statement leaves the transaction unable to execute queries.
      assert {:error, %Postgrex.Error{}} = Repo.query("SELECT 1 / 0", [], log: false)

      conn = get(conn, ~p"/up")

      assert json_response(conn, 503) == %{"status" => "error"}
      Repo.rollback(:database_unavailable)
    end)
  end
end
