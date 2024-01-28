import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :hamster_travel, HamsterTravel.Repo,
  username: "postgres",
  password: "postgres",
  database: "hamster_travel_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: System.get_env("POSTGRES_PORT", "6000"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hamster_travel, HamsterTravelWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "bzF8EWBJ+pkl2OM+PqSzBYcjf1WOthtn/Hl7Nluh2b+JuvuGjPGHnRx4hTERT0qx",
  server: false

# In test we don't send emails.
config :hamster_travel, HamsterTravel.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :hamster_travel, HamsterTravelWeb.Telemetry,
  report_metrics: false,
  periodic_measurements_enabled: false
