import Config

# Configure your database
config :hamster_travel, HamsterTravel.Repo,
  username: "postgres",
  password: "postgres",
  database: "hamster_travel_dev",
  hostname: "localhost",
  port: 6000,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :hamster_travel, HamsterTravelWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "x6soMyzjJhwqH8sWVPY+MA4psvArVe3ehuqWXdrlszCqi146uHhbrg9Pflem41w3",
  watchers: [
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]},
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :hamster_travel, HamsterTravelWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/hamster_travel_web/(live|views)/.*(ex)$",
      ~r"lib/hamster_travel_web/templates/.*(eex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :hamster_travel, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include HEEx debug annotations as HTML comments in rendered markup
  debug_heex_annotations: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

config :ex_money,
  auto_start_exchange_rate_service: true,
  # 10 hours
  exchange_rates_retrieve_every: 36_000_000,
  open_exchange_rates_app_id: {:system, "OPEN_EXCHANGE_RATES_APP_ID"}
