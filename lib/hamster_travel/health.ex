defmodule HamsterTravel.Health do
  @moduledoc "Checks application dependencies for readiness."

  alias HamsterTravel.Repo

  @spec check_database() :: :ok | {:error, term()}
  def check_database do
    case Repo.query("SELECT 1", [], timeout: 1_000, log: false) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  rescue
    error in DBConnection.ConnectionError -> {:error, error}
  end
end
