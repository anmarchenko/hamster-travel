import Config

config :hamster_travel, :mapbox,
  access_token: System.get_env("MAPBOX_ACCESS_TOKEN"),
  style_url: System.get_env("MAPBOX_STYLE_URL")

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :hamster_travel, HamsterTravel.Repo,
    ssl: false,
    socket_options: [:inet6],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :hamster_travel, HamsterTravelWeb.Endpoint,
    server: true,
    url: [host: System.get_env("PHX_HOST"), port: 80],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: 4000
    ],
    secret_key_base: secret_key_base

  config :hamster_travel, HamsterTravelWeb.Telemetry,
    report_metrics: true,
    periodic_measurements_enabled: false

  config :ex_money,
    auto_start_exchange_rate_service: true,
    # 2 hours
    exchange_rates_retrieve_every: 7_200_000,
    open_exchange_rates_app_id: System.fetch_env!("OPEN_EXCHANGE_RATES_APP_ID")
end
