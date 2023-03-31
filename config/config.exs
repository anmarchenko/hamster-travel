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
  render_errors: [view: HamsterTravelWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HamsterTravel.PubSub,
  live_view: [signing_salt: "ZN8HpKjW"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :hamster_travel, HamsterTravel.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.13.9",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.0",
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

config :petal_components,
       :error_translator_function,
       {HamsterTravelWeb.ErrorHelpers, :translate_error}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
