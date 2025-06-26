# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :hamster_travel,
  ecto_repos: [HamsterTravel.Repo]

# Configures the endpoint
config :hamster_travel, HamsterTravelWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: HamsterTravelWeb.ErrorHTML, json: HamsterTravelWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HamsterTravel.PubSub,
  live_view: [signing_salt: "ZN8HpKjW"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.12",
  default: [
    args: ~w(
            --config=tailwind.config.js
            --input=css/app.css
            --output=../priv/static/assets/app.css
            ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Use Jason for currency and localisation
config :ex_cldr,
  json_library: Jason

config :ex_money,
  json_library: Jason,
  default_cldr_backend: HamsterTravelWeb.Cldr

config :petal_components,
       :error_translator_function,
       {HamsterTravelWeb.CoreComponents, :translate_error}

config :hamster_travel, HamsterTravelWeb.Telemetry,
  report_metrics: false,
  periodic_measurements_enabled: false

config :hamster_travel, :geonames_req_options, []

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
