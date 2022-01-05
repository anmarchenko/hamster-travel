defmodule HamsterTravel.Repo do
  use Ecto.Repo,
    otp_app: :hamster_travel,
    adapter: Ecto.Adapters.Postgres
end
