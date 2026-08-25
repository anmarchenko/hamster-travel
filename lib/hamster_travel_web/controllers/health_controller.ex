defmodule HamsterTravelWeb.HealthController do
  use HamsterTravelWeb, :controller

  def show(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
