defmodule HamsterTravelWeb.HealthController do
  use HamsterTravelWeb, :controller

  alias HamsterTravel.Health

  def show(conn, _params) do
    case Health.check_database() do
      :ok -> json(conn, %{status: "ok"})
      {:error, _reason} -> conn |> put_status(:service_unavailable) |> json(%{status: "error"})
    end
  end
end
